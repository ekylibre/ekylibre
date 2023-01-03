# frozen_string_literal: true

require 'test_helper'

module TechnicalItineraries
  module Itk
    class CreateTacticTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures

      test '#create_or_update_activity_tactic if technical_workflow' do
        activity = create(:activity, reference_name: :vine )
        technical_workflow = TechnicalWorkflow.of_production(:vine).first
        campaign = Campaign.current.last

        activity_tactic = CreateTactic.new(activity: activity, technical_workflow: technical_workflow, technical_sequence: nil, campaign: campaign).create_or_update_activity_tactic

        assert_equal(5, activity_tactic.mode_delta)
        assert_equal("sowed", activity_tactic.mode)
        assert_equal(Date.new(2016, 1, 11), activity_tactic.planned_on)
        assert_equal("Vigne large | P-1", activity_tactic.name)
        assert_equal("vine_farming_vine_intensive_farming_before_planting", activity_tactic.technical_workflow_id)
      end

      test '#create_or_update_activity_tactic if technical_sequence' do
        activity = create(:activity, reference_name: :vine )
        technical_sequence = TechnicalSequence.of_production(:vine).first
        campaign = Campaign.current.last

        activity_tactic = CreateTactic.new(activity: activity, technical_workflow: nil, technical_sequence: technical_sequence, campaign: campaign).create_or_update_activity_tactic

        assert_equal(nil, activity_tactic.planned_on)
        assert_equal("Vigne large | raisonnée", activity_tactic.name)
        assert_equal("vitis_integrated", activity_tactic.technical_sequence_id)
      end

      test '#create_procedures_and_intervention_templates' do
        temp_pn = ProductNature.first
        activity = create(:activity, reference_name: :vine )
        technical_workflow = TechnicalWorkflow.find('vine_farming_vine_organic_farming_organic_before_plain_prod')
        campaign = Campaign.current.last
        technical_itinerary = TechnicalItinerary.import_from_lexicon(campaign: campaign, activity: activity, technical_workflow_id: technical_workflow.id)
        technical_itinerary_intervention_template_ids = CreateTactic.new(activity: activity, technical_workflow: nil, technical_sequence: nil, campaign: campaign)
                                                                    .create_procedures_and_intervention_templates(technical_itinerary, temp_pn )
        ti_inter_templates = TechnicalItineraryInterventionTemplate.all
        ti_inter_template_ids = ti_inter_templates.pluck(:id)
        assert_equal( ti_inter_template_ids.sort, technical_itinerary_intervention_template_ids.sort, "Return ids")

        positions = ti_inter_templates.all.pluck(:position).sort

        assert_equal((0..31).to_a, positions, 'Recompute positions for technical itinerary intervention templates')
        ti_inter_template_with_last_position = ti_inter_templates.find_by(position: 31)

        expected_attributes = {
          # technical_itinerary_id: 8,
          # intervention_template_id: 206,
          day_since_start: 0.28e3,
          repetition: 1,
          frequency: 'per_year'
        }

        assert_attributes_equal(expected_attributes, ti_inter_template_with_last_position)
        assert_equal(26, InterventionTemplate.count)

        intervention_template = InterventionTemplate.first

        product_parameters = intervention_template.product_parameters
        assert_equal(4, product_parameters.count)

        product_parameter = product_parameters.first
        expected = {
          # intervention_template_id: 16,
          # product_nature_id: 62,
          # product_nature_variant_id: 76,
          # activity_id: 25,
          quantity: 0.1e1,
          unit: "unit",
          type: "InterventionTemplate::Doer",
          procedure: { "name"=>"", "type"=>"driver" },
          intervention_model_item_id: "FER_COM_LV_driver_permanent_worker",
          technical_workflow_procedure_item_id: nil,
        }
        assert_attributes_equal(expected, product_parameter)

        assert_equal(26, InterventionTemplateActivity.count)
      end

      def assert_attributes_equal(expected, resource)
        attribute_names = expected.keys.map(&:to_s)
        attributes = resource.attributes.slice(*attribute_names)
        assert_equal(expected.with_indifferent_access, attributes)
      end
    end
  end
end
