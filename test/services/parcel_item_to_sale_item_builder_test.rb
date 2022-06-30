require 'test_helper'

class ParcelItemToSaleItemBuilderTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  setup do
    @product = create(:deliverable_product)
    @parcel_item = create(:shipment_item, source_product: @product)
    @product.variant.category.update(saleable: true)
  end

  test "If parcel item product is not saleable, it doesn't build sale item " do
    @product.variant.category.update(saleable: false)
    sale = ParcelItemToSaleItemBuilder.new(parcel_item: @parcel_item).call
    refute sale
  end

  test "If parcel item population is null, it doesn't build sale item " do
    @parcel_item.update(population: 0)
    sale = ParcelItemToSaleItemBuilder.new(parcel_item: @parcel_item).call
    refute sale
  end

  test '#It create a new sale with correct attributes' do
    @parcel_item.update(unit_pretax_sale_amount: 1000.0)
    parcel_item = ParcelItemToSaleItemBuilder.new(parcel_item: @parcel_item).call
    expected_object = OpenStruct.new(
      variant: @parcel_item.variant,
      unit_pretax_amount: 1000,
      amount: 1000,
      conditioning_unit: @parcel_item.conditioning_unit,
      conditioning_quantity: @parcel_item.conditioning_quantity,
      tax: Tax.current.first,
      shipment_item_id: @parcel_item.id,
      quantity: @parcel_item.population
    )

    objects_have_same_properties(expected_object, parcel_item)
  end

  test 'If parcel item unit_pretax_sale_amount is null & sale item of same variant exist' do
    sale_item = create(:sale_item, variant: @parcel_item.variant)
    sale = ParcelItemToSaleItemBuilder.new(parcel_item: @parcel_item).call
    assert_equal(sale_item.unit_pretax_amount, sale.unit_pretax_amount)
    assert_equal(sale_item.tax, sale.tax)
  end

  test 'By default it takes the variant category tax' do
    tax = create(:tax)
    @parcel_item.variant.category.sale_taxes << tax
    sale = ParcelItemToSaleItemBuilder.new(parcel_item: @parcel_item).call
    assert_equal(tax, sale.tax)
  end

  private

    def objects_have_same_properties(expected, actual)
      expected_attributes = expected.to_h.keys
      expected_attributes.each do |expected_attribute|
        assert_equal(expected.send(expected_attribute), actual.send(expected_attribute))
      end
    end
end
