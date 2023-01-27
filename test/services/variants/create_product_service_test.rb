require 'test_helper'

module Variants
  class CreateProductServiceTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
    setup do
      variant = create(:deliverable_variant)
      @stockable_variant = variant.becomes(variant.type.constantize)
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
      assert_equal 'Matter', created_product.type
    end

    test "if the variant has an enventory, it creates a new product born one day after the inventory" do
      inventory = build_stubbed(:inventory,
                                achieved_at: DateTime.new(2021, 0o1, 0o1),
                                year: 2021,
                                financial_year: build_stubbed(:financial_year, year: 2021))
      @stockable_variant.stub(:last_inventory, inventory) do
        Variants::CreateProductService.call(variant: @stockable_variant, current_time: DateTime.new(2021, 0o1, 0o1))
      end
      variant = @stockable_variant.reload
      created_product = variant.products.first
      assert_equal DateTime.new(2021, 0o1, 0o2), created_product.born_at
    end
  end
end
