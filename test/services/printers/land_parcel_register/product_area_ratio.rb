require 'test_helper'

module Printers
  module LandParcelRegister
    class LandParcelRegisterPrinterBaseTest < Ekylibre::Testing::ApplicationTestCase
      setup do
        @printer = LandParcelRegisterPrinterBase.new
      end

      test 'product_area_ratio computes the area ratio of the targets compared to the intervention total worked area' do
        targets = [
          { product: :prod1, working_area: 1.in_square_meter },
          { product: :prod2, working_area: 1.in_square_meter },
          { product: :prod1, working_area: 1.in_square_meter },
          { product: :prod3, working_area: 1.in_square_meter },
        ]
        target_mocks = targets.map(&method(:make_target_mock))

        intervention = Minitest::Mock.new(Object.new)
        intervention.expect :targets, target_mocks

        result = @printer.product_area_ratio(%i[prod2 prod3], intervention)
        assert_equal 0.5, result

        intervention.verify
        target_mocks.each(&:verify)
      end

      test 'product_area_ratio handle multiple units' do
        targets = [
          { product: :prod1, working_area: 10000.in_square_meter },
          { product: :prod2, working_area: 1.in_hectare },
        ]
        target_mocks = targets.map(&method(:make_target_mock))

        intervention = Minitest::Mock.new(Object.new)
        intervention.expect :targets, target_mocks

        result = @printer.product_area_ratio(:prod1, intervention)
        assert_equal 0.5, result

        intervention.verify
        target_mocks.each(&:verify)
      end

      test 'product_area_ratio defaults to 0 if no working_area' do
        targets = [
          { product: :prod1, working_area: nil },
          { product: :prod2, working_area: nil },
          { product: :prod1, working_area: nil },
          { product: :prod3, working_area: nil },
        ]
        target_mocks = targets.map(&method(:make_target_mock))

        intervention = Minitest::Mock.new(Object.new)
        intervention.expect :targets, target_mocks

        result = @printer.product_area_ratio(%i[prod2 prod3], intervention)
        assert_equal 0, result

        intervention.verify
        target_mocks.each(&:verify)
      end

      test 'product_area_ratio defaults ignore records with no target area' do
        targets = [
          { product: :prod1, working_area: nil }, # ignored, even if asking for ratio of prod1
          { product: :prod2, working_area: 1.in_hectare },
          { product: :prod1, working_area: 1.in_hectare },
        ]
        target_mocks = targets.map(&method(:make_target_mock))

        intervention = Minitest::Mock.new(Object.new)
        intervention.expect :targets, target_mocks

        assert_equal 0.5, @printer.product_area_ratio(%i[prod1 prod3], intervention)

        intervention.verify
        target_mocks.each(&:verify)
      end

      test 'product_area_ratio defaults to 0 if target not present in the intervention' do
        targets = [
          { product: :prod2, working_area: 1.in_hectare },
          { product: :prod1, working_area: 1.in_hectare },
        ]
        target_mocks = targets.map(&method(:make_target_mock))

        intervention = Minitest::Mock.new(Object.new)
        intervention.expect :targets, target_mocks

        assert_equal 0, @printer.product_area_ratio(%i[prod3], intervention)

        intervention.verify
        target_mocks.each(&:verify)
      end
    end
  end
end
