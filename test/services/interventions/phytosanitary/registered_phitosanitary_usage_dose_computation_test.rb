require 'test_helper'

module Interventions
  module Phytosanitary
    class RegisteredPhytosanitaryUsageDoseComputationTest < Ekylibre::Testing::ApplicationTestCase
      class ProductMock
        def has_indicator?(indicator)
          %i[net_mass net_volume].include?(indicator.to_sym)
        end

        def net_mass
          2.0.in(:kilogram)
        end

        def net_volume
          3.0.in(:liter)
        end
      end

      class NoIndicatorProductMock
        def has_indicator?(indicator)
          false
        end
      end

      class UsageMock
        attr_reader :dose_unit

        def initialize(dose_unit)
          @dose_unit = dose_unit
        end

        def of_dimension?(dim)
          dimension.eql?(dim)
        end

        def among_dimensions?(*dims)
          dims.include?(dimension)
        end
      end

      setup do
        @targets_area = {"0" => {shape: Charta.new_geometry("SRID=4326;GeometryCollection (Polygon ((-0.78234864413389 45.80315394565934, -0.7814045065606479 45.80410007498097, -0.7775850409234408 45.80380838465042, -0.778599307523109 45.80205583444929, -0.78234864413389 45.80315394565934)))")}}
        @service = RegisteredPhytosanitaryUsageDoseComputation.build
      end

      # No conversion
      test 'no conversion between user input and usage' do
        cases = [
          [1.in(:kilogram), UsageMock.new(:kilogram), ProductMock.new, @targets_area, nil, Measure.new(1.0, :kilogram)],
          [1.in(:liter), UsageMock.new(:liter), ProductMock.new, @targets_area, nil, Measure.new(1.0, :liter)]
        ]

        stub_many_with(cases)
      end

      # Population => mass/volume
      test 'convert population into mass or volume' do
        cases = [
          [1.in(:population), UsageMock.new(:kilogram), ProductMock.new, @targets_area, nil, Measure.new(2.0, :kilogram)],
          [1.in(:population), UsageMock.new(:liter), ProductMock.new, @targets_area, nil, Measure.new(3.0, :liter)]
        ]

        stub_many_with(cases)
      end

      # area_density => mass/volume
      test 'convert area density into mass or volume' do
        cases = [
          [1.in(:liter_per_hectare), UsageMock.new(:liter), ProductMock.new, @targets_area, nil, Measure.new(5.0, :liter)],
          [1.in(:kilogram_per_hectare), UsageMock.new(:kilogram), ProductMock.new, @targets_area, nil, Measure.new(5.0, :kilogram)]
        ]

        stub_many_with(cases)
      end

      # volume/mass => area_density
      test 'convert volume or mass into area_density' do
        cases = [
          [1.in(:kilogram), UsageMock.new(:kilogram_per_hectare), ProductMock.new, @targets_area, nil, Measure.new(1.0/5.0, :kilogram_per_hectare)],
          [1.in(:kilogram), UsageMock.new(:liter_per_hectare), ProductMock.new, @targets_area, nil, Measure.new(0.3, :liter_per_hectare)]
        ]

        stub_many_with(cases)
      end

      # volume_area_density => mass*
      test 'convert volume_area_density into mass' do
        cases = [
          [1.in(:liter_per_hectare), UsageMock.new(:kilogram), ProductMock.new, @targets_area, nil, Measure.new(5.0*2.0/3.0, :kilogram)]
        ]

        stub_many_with(cases)
      end

      # volume_concentration/specific_weight => volume_concentration/specific_weight
      test 'no conversion for specific_weight and volume_concentration' do
        cases = [
          [1.in(:liter_per_hectoliter), UsageMock.new(:liter_per_hectoliter), ProductMock.new, @targets_area, nil, Measure.new(1.0, :liter_per_hectoliter)],
          [1.in(:kilogram_per_hectoliter), UsageMock.new(:kilogram_per_hectoliter), ProductMock.new, @targets_area, nil, Measure.new(1.0, :kilogram_per_hectoliter)]
        ]

        stub_many_with(cases)
      end

      # volume_concentration => volume
      test 'convert volume_concentration into volume' do
        cases = [
          [1.in(:liter_per_hectoliter), UsageMock.new(:liter), ProductMock.new, @targets_area, 5.0, Measure.new(0.25, :liter)],
          [1.in(:liter_per_hectoliter), UsageMock.new(:liter), ProductMock.new, @targets_area, nil, nil]
        ]

        stub_many_with(cases)
      end

      # specific_weight => mass
      test 'convert specific_weight into mass' do
        cases =[
          [1.in(:kilogram_per_hectoliter), UsageMock.new(:kilogram), ProductMock.new, @targets_area, 5.0, Measure.new(0.25, :kilogram)],
          [1.in(:kilogram_per_hectoliter), UsageMock.new(:kilogram), ProductMock.new, @targets_area, nil, nil]
        ]

        stub_many_with(cases)
      end

      # volume_concentration => mass
      test 'convert volume_concentration into mass' do
        cases = [
          [1.in(:liter_per_hectoliter), UsageMock.new(:kilogram), ProductMock.new, @targets_area, 5.0, Measure.new(0.25*2.0/3.0, :kilogram)]
        ]

        stub_many_with(cases)
      end

      # specific_weight => volume
      test 'convert specific_weight into volume' do
        cases = [
          [1.in(:kilogram_per_hectoliter), UsageMock.new(:liter), ProductMock.new, @targets_area, 5.0, Measure.new(0.25*3.0/2.0, :liter)]
        ]

        stub_many_with(cases)
      end

      # specific_weight => mass_area_density
      test 'convert specific_weight into mass_area_density' do
        cases = [
          [1.in(:kilogram_per_hectoliter), UsageMock.new(:kilogram_per_hectare), ProductMock.new, @targets_area, 5.0, Measure.new(1.0*5.0/100.0, :kilogram_per_hectare)]
        ]

        stub_many_with(cases)
      end

      # specific_weight => volume_area_density
      test 'convert specific_weight into volume_area_density' do
        cases = [
          [1.in(:kilogram_per_hectoliter), UsageMock.new(:liter_per_hectare), ProductMock.new, @targets_area, 5.0, Measure.new(1.0*3.0/2.0*5.0/100.0, :liter_per_hectare)]
        ]

        stub_many_with(cases)
      end

      # volume_concentration => volume_area_density
      test 'convert volume_concentration into volume_area_density' do
        cases = [
          [1.in(:liter_per_hectoliter), UsageMock.new(:liter_per_hectare), ProductMock.new, @targets_area, 5.0, Measure.new(1.0*5.0/100.0, :liter_per_hectare)]
        ]

        stub_many_with(cases)
      end

      # volume_concentration => mass_area_density
      test 'convert volume_concentration into mass_area_density' do
        cases = [
          [1.in(:liter_per_hectoliter), UsageMock.new(:liter_per_hectare), ProductMock.new, @targets_area, 5.0, Measure.new(1.0*5.0/100.0, :liter_per_hectare)]
        ]

        stub_many_with(cases)
      end

      # @param [Array] cases
      #   cases array order = [quantity, usage, product, targets_data, indicator, spray_volume, expected_result]
      def stub_many_with(cases)
        stub_many @service, compute_area: 50000.0.in(:square_meter).in(:hectare) do
          cases.each do |values|
            *params, expected = values
            if expected.nil?
              assert_nil @service.send(:compute_user_measure, *params)
            else
              assert_measure_equal expected, @service.send(:compute_user_measure, *params)
            end
          end
        end
      end

      def assert_measure_equal(expected, value, message = nil, round: 12)
        assert expected.is_a?(Measure)
        assert value.is_a?(Measure), "Expected Measure, got #{value.inspect}"
        assert_equal expected.unit, value.unit

        assert_almost_equal round, expected.value, value.value, message
      end

      def assert_almost_equal(round, expected, value, message = nil)
        assert_equal expected.round(round), value.round(round), message
      end

      test 'compute dose message' do
        units = %i[kilogram liter kilogram_per_hectare liter_per_hectare kilogram_per_hectoliter liter_per_hectoliter]

        units.each do |unit|
          cases = [
            [Measure.new(1.0, unit), Measure.new(2.0, unit), { go: :dose_less_than_max.tl }],
            [Measure.new(1.0, unit), Measure.new(1.0, unit), { caution: :dose_equal_to_max.tl }],
            [Measure.new(2.0, unit), Measure.new(1.0, unit), { stop: :dose_bigger_than_max.tl }]
          ]

          cases.each do |values|
            *params, expected = values
            assert expected, @service.send(:compute_dose_message, *params)
          end
        end
      end
    end
  end
end
