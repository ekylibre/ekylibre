# frozen_string_literal: true

require 'test_helper'

module Interventions
  module Phytosanitary
    class DoseValidationValidatorTest < Ekylibre::Testing::ApplicationTestCase
      setup do
        @validator = DoseValidationValidator.new(
          targets_zone: [],
          unit_converter: ProductUnitConverter.new
        )

        @prod_usage = Models::ProductWithUsage.from_intervention(create(:intervention, :spraying)).first
      end

      test 'it returns none when the usage does not have a valid unit' do
        # Replace build_params to simulate the absence of unit for the usage
        def @validator.build_params(product_usage)
          {
            into: None(),
            area: Maybe(3.in(:hectare)),
            net_mass: Maybe(3.in(:kilogram)),
            net_volume: Maybe(3.in(:liter)),
            spray_volume: None()
          }
        end

        result = @validator.validate_dose(@prod_usage)

        assert_equal :unknown, result.product_vote(@prod_usage.product)
      end
    end
  end
end
