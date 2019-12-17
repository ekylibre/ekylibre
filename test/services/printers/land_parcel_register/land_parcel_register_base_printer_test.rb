require 'test_helper'

module Printers
  module LandParcelRegister
    class LandParcelRegisterPrinterBaseTest < Ekylibre::Testing::ApplicationTestCase
      setup do
        template = Minitest::Mock.new
        template.expect :nature, :land_parcel_register
        template.expect :nil?, false
        template.expect :managed?, true
        @printer = LandParcelRegisterPrinterBase.new template: template
      end

      test 'target_working_area default to 0 if no working_area in the target' do
        target = Minitest::Mock.new(Object.new)
        # target.expect :nil?, false
        target.expect :working_area, nil

        result = @printer.target_working_area(target)

        assert result.is_a? Measure
        assert_equal 0.to_d, result.to_d

        target.verify
      end

      test 'targets_working_area gets the working_area of all the targets provided' do
        target1 = Minitest::Mock.new(Object.new)
        target1.expect :working_area, 42.in_square_meter
        target2 = Minitest::Mock.new(Object.new)
        target2.expect :working_area, nil
        intervention = Minitest::Mock.new(Object.new)
        intervention.expect :targets, [target1, target2]

        result = @printer.targets_working_area(intervention)

        result.each do |e|
          assert e.second.is_a?(Measure)
        end
        assert_equal 42.to_d, result.first.second.to_d.get
        assert_equal 0.to_d, result.second.second.to_d.get

        intervention.verify
        target2.verify
        target1.verify
      end

      test 'products_working_areas computes the area worked for each product(target) given' do
        targets = [
          { product: :prod1, working_area: 1.in_square_meter },
          { product: :prod2, working_area: 1.in_square_meter },
          { product: :prod1, working_area: 1.in_square_meter },
        ]
        target_mocks = targets.map(&method(:make_target_mock))

        intervention = Minitest::Mock.new(Object.new)
        intervention.expect :targets, target_mocks

        result = @printer.products_working_areas(intervention)
        assert_equal 2.in_square_meter, result[:prod1].get
        assert_equal 1.in_square_meter, result[:prod2].get

        intervention.verify
        target_mocks.each &:verify
      end

      test 'weight_quantity_by_area does nothing if the quantity has a repartition_dimension in surface_area' do
        qt = 42.in(:quintal_per_hectare)

        assert_equal qt, @printer.weight_quantity_by_area(qt, nil, nil)
      end

      test 'weight_quantity_by_area multiplies the quantity by the computed area ration for the given product' do
        qt = 42.in(:quintal)

        @printer.stub :product_area_ratio, 0.5.to_d do
          assert_equal 21.in(:quintal), @printer.weight_quantity_by_area(qt, :target, :intervention)
        end
      end

      test 'intervention_working_area_for gets the total working area for the given products during the given intervention' do
        targets = [
          { product: :prod1, working_area: 1.in_square_meter },
          { product: :prod2, working_area: 1.in_square_meter },
          { product: :prod1, working_area: 1.in_square_meter },
          { product: :prod3, working_area: 1.in_square_meter },
        ]
        target_mocks = targets.map(&method(:make_target_mock))

        intervention = Minitest::Mock.new(Object.new)
        intervention.expect :targets, target_mocks

        result = @printer.intervention_working_area_for(%i[prod1 prod3], intervention)
        assert_equal 3.in_square_meter, result.get

        intervention.verify
        target_mocks.each &:verify
      end

      test 'normalize_to_base_unit does nothing if the measure does not have a repartition dimension in surface_area' do
        hl = 25.in(:hectoliter)

        assert_equal hl, @printer.normalize_to_base_unit(hl, nil)
      end

      test 'normalize_to_base_unit trasforms a yield to the amount based on the given area' do
        hl = 12.in(:hectoliter_per_hectare)

        assert_equal 6.in(:hectoliter), @printer.normalize_to_base_unit(hl, 0.5.in(:hectare))
      end

      test 'auto_size_quantity_unit does nothing to unknown units' do
        quantity = 25.in(:kilogram)

        assert_equal quantity, @printer.auto_size_quantity_unit(quantity)
      end

      test 'auto_size_quantity_unit resizes quintal and hectoliter' do
        cases = [
          [5.in(:quintal), 5.in(:quintal)],
          [5.in(:hectoliter), 5.in(:hectoliter)],
          [0.9.in(:hectoliter), 90.in(:liter)],
          [0.9.in(:quintal), 90.in(:kilogram)],
          [75.in(:hectoliter), 7.5.in(:cubic_meter)],
          [75.in(:quintal), 7.5.in(:ton)],
        ]

        cases.each do |value, expected|
          assert_equal expected, @printer.auto_size_quantity_unit(value), "#{value} should be #{expected}"
        end
      end

      private

        def make_target_mock(**options)
          target = Minitest::Mock.new(Object.new)
          options.each do |name, value|
            target.expect name, value
          end
          target
        end
    end
  end
end
