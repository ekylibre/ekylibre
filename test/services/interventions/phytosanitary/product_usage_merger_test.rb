require 'test_helper'

module Interventions
  module Phytosanitary
    class ProductUsageMergerTest < Ekylibre::Testing::ApplicationTestCase
      setup do
        @converter = Interventions::ProductUnitConverter.new
        @merger = ProductUsageMerger.new(area: Maybe(5.in(:hectare)), converter: @converter)

        ProductNatureVariant.import_from_lexicon('2160478_slider')
        ProductNatureVariant.import_from_lexicon('2000087_copless')

        @product1_1 = create(:phytosanitary_product, variant: ProductNatureVariant.find_by_reference_name('2160478_slider'))
        # @product1_2 = create(:phytosanitary_product, variant: @product1_1.variant)
        @product2 = create(:phytosanitary_product, variant: ProductNatureVariant.find_by_reference_name('2000087_copless'))

        @product1_1_usage = @product1_1.phytosanitary_product.usages.first
        @product2_usage1 = @product2.phytosanitary_product.usages.first
        @product2_usage2 = @product2.phytosanitary_product.usages.second

        @pu1_1 = Models::ProductWithUsage.new(@product1_1, @product1_1.phytosanitary_product, @product1_1_usage, Measure.new(1, :kilogram), nil)
        @pu1_1_2 = Models::ProductWithUsage.new(@product1_1, @product1_1.phytosanitary_product, @product1_1_usage, Measure.new(1, :kilogram), nil)
        @pu1_1_3 = Models::ProductWithUsage.new(@product1_1, @product1_1.phytosanitary_product, @product1_1_usage, Measure.new(1, :kilogram_per_hectare), nil)

        # @pu1_2 = Models::ProductWithUsage.new(@product1_2, nil, nil, nil, nil)
        @pu2_1 = Models::ProductWithUsage.new(@product2, @product2.phytosanitary_product, @product2_usage1, Measure.new(1, :kilogram), nil)
        @pu2_2 = Models::ProductWithUsage.new(@product2, @product2.phytosanitary_product, @product2_usage2, Measure.new(1, :kilogram), nil)

      end

      test 'it does nothing when no duplicates are provided' do
        results = @merger.merge([@pu1_1, @pu2_1])

        assert results.all?(&:success?)
        assert_equal [@pu1_1, @pu2_1], results.map(&:value)
      end

      test 'it merges PUs when they have the same maaid' do
        assert_equal 1, @merger.merge([@pu1_1, @pu1_1_2]).size
      end

      test 'it adds the quantities when merging' do
        merged = @merger.merge([@pu1_1, @pu1_1_2])

        assert_measure_equal 2.in(:kilogram), merged.first.value.measure
      end

      test 'it adds the quantity even if the dimensions are not the same' do
        merged = @merger.merge([@pu1_1, @pu1_1_3])

        assert_measure_equal 6.in(:kilogram), merged.first.value.measure
      end

      test 'it returns a MergeError when unable to convert values' do
        stub_many @converter, convert: None() do
          merged = @merger.merge([@pu1_1, @pu1_1_3])

          assert merged.first.error?
        end
      end

      test 'it fails to merge if the two usages for the same product are different' do
        result = @merger.merge([@pu2_1, @pu2_2])

        assert result.first.error?
      end

      def assert_measure_equal(expected, value)
        assert expected.is_a?(Measure), "Expected value is not a measure"
        assert value.is_a?(Measure), "Given value is not a measure"
        assert_equal expected.unit, value.unit, "Measures don't have the same unit"
        assert_equal expected.value, value.value, "Values are different"
      end
    end
  end
end
