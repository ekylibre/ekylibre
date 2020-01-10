require 'test_helper'

class ShipmentBookkeeperTest < Ekylibre::Testing::BookkeeperTestCase
  test "don't bookkeep anything if the parcel hasn't been given" do
    shipment = build(:shipment, state: :draft)
    shipment.items = 4.times.map do
      build(:shipment_item,
            population: 10,
            unit_pretax_stock_amount: 5,
            shipment: shipment,
            variant: create(:deliverable_variant))
    end
    bookkeep shipment
    assert_equal 0, entries_bookkeeped.count
  end

  test 'only bookkeeps unbilled payables if the preference says so' do
    Preference.set!(:permanent_stock_inventory, false)
    Preference.set!(:unbilled_payables, true)
    shipment = build(:shipment, state: :given)
    shipment.items = 4.times.map do
      build(:shipment_item,
            population: 10,
            unit_pretax_stock_amount: 5,
            shipment: shipment,
            variant: create(:deliverable_variant))
    end
    bookkeep shipment
    assert_equal 1, entries_bookkeeped.count
    assert_equal 4, entries_bookkeeped.first.debits.count
    assert_equal 4, entries_bookkeeped.first.credits.count

    Preference.set!(:unbilled_payables, false)
    bookkeep shipment
    assert_equal 0, entries_bookkeeped.count
  end

  test 'only bookkeeps stock inventory if the preference says so' do
    Preference.set!(:permanent_stock_inventory, true)
    shipment = build(:shipment, state: :given)
    shipment.items = 4.times.map do
      build(:shipment_item,
            population: 10,
            unit_pretax_stock_amount: 5,
            shipment: shipment,
            variant: create(:deliverable_variant))
    end
    bookkeep shipment
    assert_equal 1, entries_bookkeeped.count
    assert_equal 4, entries_bookkeeped.first.debits.count
    assert_equal 4, entries_bookkeeped.first.credits.count

    Preference.set!(:permanent_stock_inventory, false)
    bookkeep shipment
    assert_equal 0, entries_bookkeeped.count
  end
end
