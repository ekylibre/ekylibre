# frozen_string_literal: true

module Agroedi
  class DaplosExchanger < ActiveExchanger::Base
    category :plant_farming
    vendor :agroedi

    attr_reader :children

    def check
      valid = true
      if daplos?
        crops = daplos&.interchange&.crops
        i_count = crops.flat_map(&:interventions).compact.count if crops.any?
        w.count = i_count
        # false if no crops and no interventions
        if crops.count == 0 && i_count == 0
          valid = false
        else
          crops.each do |crop|
            crop_specie = crop.crop_specie_edicode
            prods = MasterCropProduction.where(agroedi_crop_code: crop_specie)
            transcode_species = RegisteredAgroediCode.of_ekylibre_codes('MasterCropProduction', crop_specie).pluck(:ekylibre_value).compact.uniq
            if prods.count > 0
              w.info "Production nature exist for #{crop_specie}"
              valid = true
            elsif transcode_species.count > 0
              w.info "Production nature transcoding exist for #{crop_specie}"
              valid = true
            else
              w.error "No Production nature transcoding exist for #{crop_specie}"
              valid = false
            end
            crop.interventions.each do |intervention|
              code = intervention.intervention_nature_edicode
              start_on = Date.parse(intervention.intervention_started_at)
              # false if no RegisteredAgroediCode exist
              unless RegisteredAgroediCode.find_by(repository_id: 14, reference_code: code)
                w.error "No reference found for EDICODE : #{code} on repository 14"
                valid = false
              end
              # false if no FinancialYear exist on intervention start
              unless FinancialYear.on(start_on)
                w.error "No FinancialYear exist at #{start_on.l}. Please create it"
                valid = false
              end
            end
          end
        end
      else
        valid = false
      end
      valid
    end

    def import
      raise ActiveExchanger::NotWellFormedFileError unless daplos?

      crops = daplos&.interchange&.crops
      raise ActiveExchanger::NotWellFormedFileError unless crops

      #+1 to account for the regrouping
      w.count = crops.flat_map(&:interventions).compact.count

      @children = {}
      crops.each do |c|
        DaplosExchanger::Crop.new(self, c).tap(&:register)
      end
      DaplosExchanger::DaplosIntervention.regroup(interventions)

      @children[:crops].each(&:import)

      regroup_interventions!
      true
    end

    def interventions
      @children[:crops].flat_map { |crop| crop.children[:interventions] }.compact
    end

    private

      def daplos
        force_utf8_encoding
        @daplos = SVF::EdiDaplos2.parse(file)
      rescue SVF::InvalidSyntax
        return false
      end
      alias_method :daplos?, :daplos

      def force_utf8_encoding
        content = File.read(file).encode("UTF-8", invalid: :replace, undef: :replace, replace: "_")
        File.write(file, content)
      end

      # TODO: Do this as pre-import work instead of destroying interventions
      def regroup_interventions!
        saved_interventions = Intervention.where(id: interventions.map(&:record).uniq.pluck(:id))

        # Grouping intervention with inputs with same inputs, same started_at and same nature
        merge_input_groups = saved_interventions.with_input_presence.reorder(:started_at).group_by do |int|
          [int.procedure_name,
           int.started_at,
           int.inputs.pluck(:product_id)]
        end

        # Reducing each group to one intervention each
        merge_input_groups.each do |_criterion, to_be_merged|
          to_be_merged.reduce do |merged_into, other_intervention|
            # Switch old targets to the new intervention
            other_intervention.targets.each do |target|
              # dont't want twice the same target if already link to keep intervention
              unless merged_into.targets.where(product_id: target.product_id).count >= 1
                target.tap(&:reload).update(intervention_id: merged_into.id)
              end
            end

            # Switch old inputs quantity to the new intervention
            other_intervention.inputs.each do |input|
              merged_input = merged_into.inputs.where(product_id: input.product_id)
              if merged_input.any?
                keep_input = merged_input.first
                keep_input.quantity_value += input.quantity_value
                keep_input.save
              end
            end

            # Merge GUIDs to ensure we don't lose history
            merged_providers = merged_into.providers || {}
            merged_guids = merged_providers['daplos_intervention_guid'] || []
            other_providers = other_intervention.providers || {}

            merged_guids += other_providers['daplos_intervention_guid'] || []

            merged_into.targets.reload
            merged_into.inputs.reload
            merged_providers.merge!('daplos_intervention_guid' => merged_guids)
            merged_into.tap(&:reload).update!(providers: merged_providers)

            other_intervention.tap(&:reload).destroy!
            merged_into.tap(&:reload)
          end
        end

        # Grouping intervention with inputs with same inputs, same started_at and same nature
        merge_no_input_groups = saved_interventions.without_input_presence.without_output_presence.reorder(:started_at).group_by do |int|
          [int.procedure_name,
           int.started_at]
        end
        # Reducing each group to one intervention each
        merge_no_input_groups.each do |_criterion, to_be_merged|
          to_be_merged.reduce do |merged_into, other_intervention|
            # Switch old targets to the new intervention
            other_intervention.targets.each do |target|
              unless merged_into.targets.where(product_id: target.product_id).count >= 1
                target.tap(&:reload).update(intervention_id: merged_into.id)
              end
            end

            # Merge GUIDs to ensure we don't lose history
            merged_providers = merged_into.providers || {}
            merged_guids = merged_providers['daplos_intervention_guid'] || []
            other_providers = other_intervention.providers || {}

            merged_guids += other_providers['daplos_intervention_guid'] || []
            merged_into.targets.reload
            merged_providers.merge!('daplos_intervention_guid' => merged_guids)
            merged_into.tap(&:reload).update!(providers: merged_providers)
            other_intervention.tap(&:reload).destroy!
            merged_into.tap(&:reload)
          end
        end

        w.check_point
      end
  end
end
