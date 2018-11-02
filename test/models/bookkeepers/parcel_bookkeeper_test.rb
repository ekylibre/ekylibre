require 'test_helper'
require 'cases/bookkeeper_test_case'

class ParcelBookkeeperTest < BookkeeperTestCase
  test "don't bookkeep anything if the parcel hasn't been given" do
    parcel = build(:parcel, state: :draft)
    parcel.items = 4.times.map do
      build(:parcel_item,
            population: 10,
            unit_pretax_stock_amount: 5,
            parcel: parcel,
            variant: create(:deliverable_variant))
    end
    bookkeep parcel
    assert_equal 0, entries_bookkeeped.count
  end

  test 'only bookkeeps unbilled payables if the preference says so' do
    Preference.set!(:permanent_stock_inventory, false)
    Preference.set!(:unbilled_payables, true)
    parcel = build(:parcel, state: :given)
    parcel.items = 4.times.map do
      build(:parcel_item,
            population: 10,
            unit_pretax_stock_amount: 5,
            parcel: parcel,
            variant: create(:deliverable_variant))
    end
    bookkeep parcel
    assert_equal 1, entries_bookkeeped.count
    assert_equal 4, entries_bookkeeped.first.debits.count
    assert_equal 4, entries_bookkeeped.first.credits.count

    Preference.set!(:unbilled_payables, false)
    bookkeep parcel
    assert_equal 0, entries_bookkeeped.count
  end

  test 'only bookkeeps stock inventory if the preference says so' do
    Preference.set!(:permanent_stock_inventory, true)
    parcel = build(:parcel, state: :given)
    parcel.items = 4.times.map do
      build(:parcel_item,
            population: 10,
            unit_pretax_stock_amount: 5,
            parcel: parcel,
            variant: create(:deliverable_variant))
    end
    bookkeep parcel
    assert_equal 1, entries_bookkeeped.count
    assert_equal 4, entries_bookkeeped.first.debits.count
    assert_equal 4, entries_bookkeeped.first.credits.count

    Preference.set!(:permanent_stock_inventory, false)
    bookkeep parcel
    assert_equal 0, entries_bookkeeped.count
  end
end
