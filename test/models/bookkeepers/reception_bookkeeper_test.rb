require 'test_helper'
require 'cases/bookkeeper_test_case'

class ReceptionBookkeeperTest < BookkeeperTestCase
  test "don't bookkeep anything if the parcel hasn't been given" do
    reception = build(:reception, state: :draft)
    reception.items = 4.times.map do
      build(:reception_item,
            population: 10,
            unit_pretax_stock_amount: 5,
            reception: reception,
            variant: create(:deliverable_variant))
    end
    bookkeep reception
    assert_equal 0, entries_bookkeeped.count
  end

  test 'only bookkeeps unbilled payables if the preference says so' do
    Preference.set!(:permanent_stock_inventory, false)
    Preference.set!(:unbilled_payables, true)
    reception = build(:reception, state: :given)
    reception.items = 4.times.map do
      build(:reception_item,
            population: 10,
            unit_pretax_stock_amount: 5,
            reception: reception,
            variant: create(:deliverable_variant))
    end
    bookkeep reception
    assert_equal 1, entries_bookkeeped.count
    assert_equal 4, entries_bookkeeped.first.debits.count
    assert_equal 4, entries_bookkeeped.first.credits.count

    Preference.set!(:unbilled_payables, false)
    bookkeep reception
    assert_equal 0, entries_bookkeeped.count
  end

  test 'only bookkeeps stock inventory if the preference says so' do
    Preference.set!(:permanent_stock_inventory, true)
    reception = build(:reception, state: :given)
    reception.items = 4.times.map do
      build(:reception_item,
            population: 10,
            unit_pretax_stock_amount: 5,
            reception: reception,
            variant: create(:deliverable_variant))
    end
    bookkeep reception
    assert_equal 1, entries_bookkeeped.count
    assert_equal 4, entries_bookkeeped.first.debits.count
    assert_equal 4, entries_bookkeeped.first.credits.count

    Preference.set!(:permanent_stock_inventory, false)
    bookkeep reception
    assert_equal 0, entries_bookkeeped.count
  end
end
