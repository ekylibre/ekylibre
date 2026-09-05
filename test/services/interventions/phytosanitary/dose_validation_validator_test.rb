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

      # Regression test for issue #2673: targets whose working_area is nil
      # (working_zone_area == 0 on the underlying InterventionProductParameter)
      # used to crash the show page with "undefined method '+' for nil" because
      # ActiveSupport's Enumerable#sum(&block) seeds the accumulator with the
      # first mapped element — a nil — and then nil + Measure exploded.
      test 'area treats nil target areas as zero and returns a square_meter Measure' do
        zones = [
          Models::TargetZone.new(:dummy_target_1, :dummy_shape, nil),
          Models::TargetZone.new(:dummy_target_2, :dummy_shape, 2.0.in(:square_meter)),
          Models::TargetZone.new(:dummy_target_3, :dummy_shape, nil)
        ]
        validator = DoseValidationValidator.new(targets_zone: zones, unit_converter: ProductUnitConverter.new)

        result = validator.send(:area)

        assert_kind_of Measure, result
        assert_equal :square_meter, result.unit
        assert_in_delta 2.0, result.to_f, 0.0001
      end

      test 'area returns a zero square_meter Measure when every target area is nil' do
        zones = [
          Models::TargetZone.new(:dummy_target_1, :dummy_shape, nil),
          Models::TargetZone.new(:dummy_target_2, :dummy_shape, nil)
        ]
        validator = DoseValidationValidator.new(targets_zone: zones, unit_converter: ProductUnitConverter.new)

        result = validator.send(:area)

        assert_kind_of Measure, result
        assert_equal :square_meter, result.unit
        assert result.zero?
      end
    end
  end
end
