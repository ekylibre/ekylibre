require 'test_helper'

class ParcelToSaleConverterTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  setup do
    @product = create(:deliverable_product)
    @parcel = create(:shipment)
    @parcel_item = create(:shipment_item, shipment: @parcel, source_product: @product)
    @product.variant.category.update(saleable: true)
  end

  attr_reader :parcel

  test '#It create a new sale with correct attributes' do
    sale = ParcelToSaleConverter.new(parcels: [parcel]).call
    expected_attributes = OpenStruct.new(
      {
        client_id: parcel.third_id,
        delivery_address: parcel.address
      }
    )
    objects_have_same_properties(expected_attributes, sale)
  end

  test '#If last parcels sale nature is not set, sale has the defaut sale nature' do
    sale = ParcelToSaleConverter.new(parcels: [parcel]).call
    assert_equal(SaleNature.by_default, sale.nature)
  end

  test '#If last parcels sale nature is set, sale take sale nature' do
    sale_nature = create(:sale_nature)
    @parcel.update(sale_nature: sale_nature)
    sale = ParcelToSaleConverter.new(parcels: [parcel]).call
    assert_equal(sale_nature, sale.nature)
  end

  test '#If last parcels sale nature is blank and there is no sale nature default, it create a new nature' do
    SaleNature.by_default.update_columns(by_default: false)
    sale = ParcelToSaleConverter.new(parcels: [parcel]).call
    expected_attributes = OpenStruct.new(
      {
        active: true,
        currency: "EUR",
        by_default: true,
        name: "Standard sale"
      }
    )
    objects_have_same_properties(expected_attributes, sale.nature)
  end

  test "If sales journal doesn't exist, it raises an error" do
    SaleNature.by_default.update_columns(by_default: false)
    assert_raises(RuntimeError) do
      sale = ParcelToSaleConverter.new(parcels: [parcel], sale_journals: Journal.none).call
    end
  end

  test "If parcels have different third, it raise an error" do
    parcel2 = create(:shipment)
    SaleNature.by_default.update_columns(by_default: false)
    assert_raises(RuntimeError) do
      sale = ParcelToSaleConverter.new(parcels: [parcel, parcel2]).call
    end
  end

  private

    def objects_have_same_properties(expected, actual)
      expected_attributes = expected.to_h.keys
      expected_attributes.each do |expected_attribute|
        assert_equal(expected.send(expected_attribute), actual.send(expected_attribute))
      end
    end

end
