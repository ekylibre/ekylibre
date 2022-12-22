require 'test_helper'

module Variants
  class CreateProductServiceTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
    setup do
      @stockable_variant = create(:deliverable_variant)
    end

    test "if the variant already exists, it does nothing" do
      assert_no_changes Product.count do
        Variants::CreateProductService.call(variant: @stockable_variant )
      end
    end

    test "if the variant doesn't exists, it creates a new product with right attributes" do
      Variants::CreateProductService.call(variant: @stockable_variant, current_time: DateTime.new(2021, 0o1, 0o1))
      variant = @stockable_variant.reload

      created_product = variant.products.first
      assert_equal variant.name, created_product.name
      assert_equal 0, created_product.initial_population
      assert_equal variant.default_unit, created_product.unit
      assert_equal DateTime.new(2020, 0o1, 0o1), created_product.born_at
    end
  end
end
