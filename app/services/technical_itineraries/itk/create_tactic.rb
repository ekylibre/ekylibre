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
        planned_on = at.planned_on || sowed_started_on
        return at if at.technical_itinerary

        attributes = if @technical_workflow
                       if at.technical_workflow
                         { planned_on: planned_on }
                       else
                         {
                           planned_on: planned_on,
                           mode: :sowed,
                           mode_delta: 5,
                           name: @technical_workflow.translation.send(Preference[:language]),
                           technical_workflow_id: @technical_workflow.id
                         }
                       end
                     elsif @technical_sequence
                       if at.technical_sequence
                         { planned_on: planned_on }
                       else
                         {
                           planned_on: planned_on,
                           name: @technical_sequence.translation.send(Preference[:language]),
                           technical_sequence_id: @technical_sequence.id
                         }
                       end
                     end

        return nil unless attributes

        at.attributes = attributes
        at.save!
        at
      end

      def create_procedures_and_intervention_templates(ti, temp_pn)
        tiit_ids = []
        ti.technical_workflow.procedures.each do |twp|
          # 21 - find detail reference procedure in InterventionModel (IM)
          im = InterventionModel.find_by(reference_name: twp.procedure_reference)
          next unless im

          # 21 - Create IT from InterventionModel (IM)
          it = InterventionTemplate.import_from_lexicon(technical_workflow_procedure: twp, intervention_model: im, campaign: @campaign )

          # 30 create all ITPP from InterventionModelItems IMI in Lexicon
          create_imi(im, it, temp_pn)

          # 31 update all ITPP
          itpps = InterventionTemplate::ProductParameter.where(intervention_template_id: it.id, activity_id: @activity.id, intervention_model_item_id: im.items.pluck(:reference_name))
          update_itpp(itpps, twp, it)

          # 40 - create TIIT link to TI, IT, TWP
          update_or_create_tiit(ti, it, twp)

          recompute_position_for_tiit(ti)
          # 41 - create ITA link to A, IT
          ita = InterventionTemplateActivity.find_or_create_by!(intervention_template_id: it.id, activity_id: @activity.id)
          # end
        end
        tiit_ids = TechnicalItineraryInterventionTemplate.where(technical_itinerary_id: ti.id).pluck(:id)
        tiit_ids
      end

      private

        def create_imi(im, it, temp_pn)
          im.items.each do |imi|
            temp_itpp = InterventionTemplate::ProductParameter.find_or_initialize_by(intervention_template_id: it.id, activity_id: @activity.id, intervention_model_item_id: imi.reference_name)
            temp_itpp.product_nature_id = temp_pn.id
            temp_itpp.product_nature_variant_id = nil
            temp_itpp.quantity = 1.0
            temp_itpp.unit = 'unit'
            temp_itpp.type = imi.product_parameter_type
            temp_itpp.procedure = { 'name' => '', 'type' => imi.procedure_item_reference }
            temp_itpp.technical_workflow_procedure_item_id = nil
            temp_itpp.save!
          end
        end

        def update_or_create_tiit(ti, it, twp)
          # basic case : 1 per_year, no conversion
          if twp.repetition == 1 && twp.frequency == 'per_year'
            tiit = TechnicalItineraryInterventionTemplate.find_or_create_by!(technical_itinerary_id: ti.id,
                                                                  intervention_template_id: it.id,
                                                                  position: twp.position,
                                                                  day_since_start: twp.period.to_f,
                                                                  repetition: 1,
                                                                  frequency: 'per_year')
          # complex case : 2 per_month, conversion per year
          else
            reps = create_repetition(twp)
            (1..reps.intervention_count).each_with_index do |_rep, index|
              tiit = TechnicalItineraryInterventionTemplate.find_or_create_by!(technical_itinerary_id: ti.id,
                                                                    intervention_template_id: it.id,
                                                                    position: (twp.position + index),
                                                                    day_since_start: reps.initial_start + (index * reps.individual_offset),
                                                                    repetition: 1,
                                                                    frequency: 'per_year')
            end
          end
        end

        def update_itpp(itpps, twp, it)
          activity_unit = @activity.size_unit_name
          itpps.each do |itpp|
            imi = InterventionModelItem.find_by_reference_name(itpp.intervention_model_item_id)
            if %i[input output].include?(itpp.find_general_product_type)
              # 311 create ITPP with TechnicalWorkflowProcedureItems TWPI if input or output
              twp.items.where(procedure_item_reference: imi.procedure_item_reference, actor_reference: %w[input output]).each do |twpi|
                if MasterVariant.find_by(reference_name: twpi.article_reference) || RegisteredPhytosanitaryProduct.find_by(id: twpi.article_reference) || RegisteredPhytosanitaryProduct.find_by(france_maaid: twpi.article_reference)
                  article = ProductNatureVariant.import_from_lexicon(twpi.article_reference)
                  base_unit = Onoma::Unit[twpi.unit] || Onoma::Unit.find_by(symbol: twpi.unit.to_s)
                  new_itpp = InterventionTemplate::ProductParameter.new
                  new_itpp.intervention_template_id = it.id
                  new_itpp.product_nature_id = nil
                  new_itpp.product_nature_variant_id = article.id
                  new_itpp.activity_id = @activity.id
                  new_itpp.quantity = twpi.quantity
                  new_itpp.type = imi.product_parameter_type
                  new_itpp.unit = "#{base_unit.name}_per_#{activity_unit}"
                  new_itpp.procedure = { 'name' => '', 'type' => imi.procedure_item_reference }
                  new_itpp.intervention_model_item_id = imi.reference_name
                  new_itpp.technical_workflow_procedure_item_id = twpi.reference_name
                  new_itpp.save!
                end
              end
              # 311 destroy blank original itpp template
              itpp.destroy
            elsif %i[tool doer].include?(itpp.find_general_product_type)
              # 312 update ITPP if tools or doer
              if MasterVariant.find_by(reference_name: imi.article_reference)
                article = ProductNatureVariant.import_from_lexicon(imi.article_reference)
                itpp.product_nature_id = article.nature.id
                itpp.product_nature_variant_id = article.id
                itpp.save!
              end
            end
          end
        end

        # return a Hash
        # of the procedure during one technical_itinerary (so one year)
        # initial_start : number of day since sowing first intervention start
        # intervention_count : number of intervention to generate
        # individual_offset : day offset of each intervention between them
        def create_repetition(twp)
          # set initial_value
          individual_offset = nil
          # get period
          period_day_start = twp.period.split('_').first.to_f
          period_day_end = twp.period.split('_').last.to_f
          period_duration = period_day_end - period_day_start
          # set global repetition on year
          if twp.frequency == 'per_year'
            rep = twp.repetition
          elsif twp.frequency == 'per_month'
            rep = twp.repetition * 12
          elsif twp.frequency == 'per_day'
            rep = twp.repetition * 365
          else
            rep = 1
          end
          if rep > 1
            individual_offset = (period_duration / (rep - 1)).to_f
          end
          { initial_start: period_day_start, intervention_count: rep, individual_offset: individual_offset }.to_struct
        end

        # reorder position after creating each items of TechnicalItinerary
        def recompute_position_for_tiit(ti)
          TechnicalItineraryInterventionTemplate.where(technical_itinerary_id: ti.id).reorder(:day_since_start).each_with_index do |tiit, index|
            tiit.position = index
            tiit.save!
          end
        end

    end
  end
end
