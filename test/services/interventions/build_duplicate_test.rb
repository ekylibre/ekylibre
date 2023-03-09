require 'test_helper'

module Interventions
  class BuildDuplicateTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
    test 'It should build new intervention with same parameters and settings' do
      # Following intervention gets 1 group parameter (containing 1 target + 1 output), 1 input, 1 setting, 1 setting parameter
      intervention = create(:sowing_intervention_with_all_parameters, :with_spraying_settings, nature: :request)

      duplicate_intervention = BuildDuplicate.call(intervention)

      assert_not_nil duplicate_intervention

      # Group parameter
      intervention_gp = intervention.group_parameters.last
      duplicate_gp = duplicate_intervention.group_parameters.last
      assert_not_nil intervention_gp
      assert_not_nil duplicate_gp

      # Targets
      assert_equal intervention_gp.targets.length, duplicate_gp.targets.length
      assert_equal intervention_gp.targets.last.product_id, duplicate_gp.targets.last.product_id

      # Outputs
      assert_equal intervention_gp.outputs.length, duplicate_gp.outputs.length
      assert_equal intervention_gp.outputs.last.quantity_population, duplicate_gp.outputs.last.quantity_population

      # Inputs
      intervention_inputs = intervention.inputs
      duplicate_inputs = duplicate_intervention.product_parameters.select{ |pp| pp.type == "InterventionInput" }
      assert_equal intervention_inputs.length, duplicate_inputs.length
      assert_equal intervention_inputs.last.product_id, duplicate_inputs.last.product_id
      assert_equal intervention_inputs.last.quantity_value, duplicate_inputs.last.quantity_value
      assert_equal intervention_inputs.last.quantity_handler, duplicate_inputs.last.quantity_handler

      # settings
      intervention_settings = intervention.settings
      duplicate_settings = duplicate_intervention.settings
      assert_equal intervention_settings.length, duplicate_settings.length

      # parameter_settings
      intervention_parameter_settings = intervention.parameter_settings
      duplicate_parameter_settings = duplicate_intervention.parameter_settings
      assert_equal intervention_parameter_settings.length, duplicate_parameter_settings.length
      intervention_parameter_setting_items = intervention.parameter_setting_items
      duplicate_parameter_setting_items = duplicate_intervention.parameter_settings.flat_map(&:settings)
      assert_equal intervention_parameter_setting_items.length, duplicate_parameter_setting_items.length
    end
  end
end
