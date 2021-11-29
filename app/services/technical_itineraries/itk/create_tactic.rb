# frozen_string_literal: true

module TechnicalItineraries
  module Itk
    class CreateTactic
      attr_reader :activity, :technical_workflow, :technical_sequence, :campaign

      def initialize(activity:, technical_workflow: nil, technical_sequence: nil, campaign:)
        @activity = activity
        @technical_workflow = technical_workflow
        @technical_sequence = technical_sequence
        @campaign = campaign
        @logger ||= Logger.new(File.join(Rails.root, 'log', "itk-#{@campaign.name}-#{Ekylibre::Tenant.current.to_s}.log"))
      end

      # 11- create AT with link to TW
      # return ActivityTactic
      def create_or_update_activity_tactic
        year_delta = @activity.production_started_on_year
        if year_delta && @technical_workflow
          sowed_started_on = Date.new((@campaign.harvest_year + year_delta), @technical_workflow.start_month, @technical_workflow.start_day)
        else
          sowed_started_on = nil
        end

        at = ActivityTactic.find_or_initialize_by(activity_id: @activity.id, campaign_id: @campaign.id, default: true)
        if @technical_workflow && at.technical_workflow
          at
        elsif @technical_workflow
          at.mode = :sowed
          at.mode_delta = 5
          at.planned_on = sowed_started_on
          at.name = @technical_workflow.translation.send(Preference[:language])
          at.technical_workflow_id = @technical_workflow.id
          at.save!
          at
        elsif @technical_sequence && at.technical_sequence
          at
        elsif @technical_sequence
          at.name = @technical_sequence.translation.send(Preference[:language])
          at.technical_sequence_id = @technical_sequence.id
          at.save!
          at
        end
      end

      def create_procedures_and_intervention_templates(ti, temp_pn)
        tiit_ids = []
        ti.technical_workflow.procedures.each do |twp|
          # 21 - find detail reference procedure in InterventionModel (IM)
          im = InterventionModel.find_by(id: twp.procedure_reference)
          if im
            @logger.info("_20 - IM exist : #{im.id}")
          else
            @logger.error("_20 - Procedure reference : #{twp.procedure_reference} doesn't exist in Lexicon")
            next
          end

          # 21 - Create IT from InterventionModel (IM)
          it = InterventionTemplate.import_from_lexicon(technical_workflow_procedure: twp, intervention_model: im, campaign: @campaign )

          # 30 create all ITPP from InterventionModelItems IMI in Lexicon
          create_imi(im, it, temp_pn)

          # 31 update all ITPP
          itpps = InterventionTemplate::ProductParameter.where(intervention_template_id: it.id, activity_id: @activity.id, intervention_model_item_id: im.items.pluck(:id))
          @logger.info("__31 - ITPP to update : #{itpps.count}")
          puts itpps.inspect.yellow
          update_itpp(itpps, twp, it)

          # 40 - create TIIT link to TI, IT, TWP
          tiit = TechnicalItineraryInterventionTemplate.find_or_create_by!(technical_itinerary_id: ti.id,
                                                                intervention_template_id: it.id,
                                                                position: twp.position,
                                                                day_since_start: twp.period.to_f,
                                                                repetition: twp.repetition,
                                                                frequency: twp.frequency)

          tiit_ids << tiit.id
          @logger.info("_40 - TIIT created #{tiit.id} from position : #{tiit.position} and day_since_start : #{tiit.day_since_start}")
          # 41 - create ITA link to A, IT
          ita = InterventionTemplateActivity.find_or_create_by!(intervention_template_id: it.id, activity_id: @activity.id)
          @logger.info("_41 - ITA created #{ita.id}")
          # end
        end
        tiit_ids
      end

      def create_imi(im, it, temp_pn)
        im.items.each do |imi|
          temp_itpp = InterventionTemplate::ProductParameter.find_or_initialize_by(intervention_template_id: it.id, activity_id: @activity.id, intervention_model_item_id: imi.id)
          temp_itpp.product_nature_id = temp_pn.id
          temp_itpp.product_nature_variant_id = nil
          temp_itpp.quantity = 1.0
          temp_itpp.unit = 'unit'
          temp_itpp.type = nil
          temp_itpp.procedure = { 'name' => '', 'type' => imi.procedure_item_reference }
          temp_itpp.technical_workflow_procedure_item_id = nil
          temp_itpp.save!
          @logger.info("__30 - ITPP created from : #{imi.id} - #{imi.procedure_item_reference}")
        end
      end

      def update_itpp(itpps, twp, it)
        activity_unit = @activity.size_unit_name
        itpps.each do |itpp|
          puts itpp.inspect.red
          imi = InterventionModelItem.find(itpp.intervention_model_item_id)
          if %i[input output].include?(itpp.find_general_product_type)
            @logger.info("__311 - Start ITPP input/output #{itpp.id}")
            # 311 create ITPP with TechnicalWorkflowProcedureItems TWPI if input or output
            twp.items.where(procedure_item_reference: imi.procedure_item_reference, actor_reference: %w[input output]).each do |twpi|
              if MasterVariant.find_by(reference_name: twpi.article_reference) || RegisteredPhytosanitaryProduct.find_by(id: twpi.article_reference) || RegisteredPhytosanitaryProduct.find_by(france_maaid: twpi.article_reference)
                article = ProductNatureVariant.import_from_lexicon(twpi.article_reference)
                unless article
                  @logger.error("__311 - article no found in Lexicon with : #{twpi.article_reference}")
                end
                base_unit = Onoma::Unit[twpi.unit] || Onoma::Unit.find_by(symbol: twpi.unit.to_s)
                @logger.info("__311 - ITPP new with : #{article.name}")
                new_itpp = InterventionTemplate::ProductParameter.new
                new_itpp.intervention_template_id = it.id
                new_itpp.product_nature_id = nil
                new_itpp.product_nature_variant_id = article.id
                new_itpp.activity_id = @activity.id
                new_itpp.quantity = twpi.quantity
                new_itpp.unit = "#{base_unit.name}_per_#{activity_unit}"
                new_itpp.procedure = { 'name' => '', 'type' => imi.procedure_item_reference }
                new_itpp.intervention_model_item_id = imi.id
                new_itpp.technical_workflow_procedure_item_id = twpi.id
                new_itpp.save!
                @logger.info("__311 - ITPP (input output) updated with TWPI : #{twpi.article_reference}")
              else
                @logger.error("__311 - article no found with : #{twpi.article_reference}")
              end
            end
            # 311 destroy blank original itpp template
            itpp.destroy
          elsif %i[tool doer].include?(itpp.find_general_product_type)
            @logger.info("__312 - Start ITPP tool/doer #{itpp.id}")
            # 312 update ITPP if tools or doer
            if MasterVariant.find_by(reference_name: imi.article_reference)
              article = ProductNatureVariant.import_from_lexicon(imi.article_reference)
              unless article
                @logger.error("__312 - article are not imported from Lexicon : #{imi.article_reference}")
              end
              itpp.product_nature_id = article.nature.id
              itpp.product_nature_variant_id = article.id
              itpp.save!
              @logger.info("__312 - ITPP (doer tool) updated with IMI : #{imi.article_reference}")
            else
              @logger.error("__312 - ITPP (doer tool) article no found with : #{imi.article_reference}")
            end
          else
            @logger.error("__312 - ITPP (id: #{itpp.id}) is not on (doer tool input output)")
          end
        end
      end

    end
  end
end
