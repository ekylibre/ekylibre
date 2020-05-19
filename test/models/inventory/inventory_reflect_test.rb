require 'test_helper'

class InventoryReflectTest < Ekylibre::Testing::ApplicationTestCase

  setup do
    fix_preferences
    @variant = ProductNatureVariant.import_from_nomenclature :hay_round_bales

    @fy = create :financial_year, year: 2018
    @catalog = create :catalog, usage: :stock
    @catalog.items.create! variant: @variant, amount: 10.0

    @product = create :matter, name: 'matter', variant: @variant
    create :journal, used_for_permanent_stock_inventory: true
  end

  test "Reflecting an inventory without previous stock initializes stock value and amount" do
    inventory = create :inventory, year: 2018, financial_year: @fy

    inventory.items.create! product: @product, expected_population: 0, actual_population: 10
    inventory.reload
    inventory.reflect!

    assert inventory.reflected?
    assert inventory.journal_entry.present?

    assert_equal 100.0, @variant.stock_account.journal_entry_items_calculate(:balance, @fy.started_on, @fy.stopped_on)
    assert_equal -100.0, @variant.stock_movement_account.journal_entry_items_calculate(:balance, @fy.started_on, @fy.stopped_on)
  end

  test "Reflecting an inventory with initial stock and no accountancy value creates the correct movement and journal_entry" do
    @product.update! initial_population: 20
    inventory = create :inventory, year: 2018, financial_year: @fy

    inventory.items.create! product: @product, expected_population: 20, actual_population: 10
    inventory.reload
    inventory.reflect!

    assert inventory.reflected?
    assert inventory.journal_entry.present?

    assert_equal -10, inventory.items.first.reload.product_movement.delta

    assert_equal 100.0, @variant.stock_account.journal_entry_items_calculate(:balance, @fy.started_on, @fy.stopped_on)
    assert_equal -100.0, @variant.stock_movement_account.journal_entry_items_calculate(:balance, @fy.started_on, @fy.stopped_on)
  end

  test "Reflecting an inventory with initial stock and initial accountancy amount creates the correct movement and journal entry" do
    journal = create :journal, nature: :forward

    JournalEntry.create! journal: journal, financial_year: @fy, printed_on: @fy.started_on, items_attributes: [
      { real_debit: 200, name: "init stock", account: @variant.stock_account },
      { real_credit: 200, name: "init stock", account: Account.find_or_create_by_number("471") }
    ]

    inventory = create :inventory, year: 2018, financial_year: @fy

    inventory.items.create! product: @product, expected_population: 20, actual_population: 10
    inventory.reload
    inventory.reflect!

    assert inventory.reflected?
    assert inventory.journal_entry.present?

    assert_equal 100.0.to_d, @variant.stock_account.journal_entry_items_calculate(:balance, @fy.started_on, @fy.stopped_on)
    # Debit in movement account is 100 here as its a loss of stock
    assert_equal 100.0.to_d, @variant.stock_movement_account.journal_entry_items_calculate(:debit, @fy.started_on, @fy.stopped_on)

    # Inventory loss should be 10
    assert_equal -10.to_d, inventory.items.first.reload.product_movement.delta
    # Entry item of stock account should be credit: 100 as we record a loss of stock
    assert_equal 100.to_d, inventory.journal_entry.items.where(account: @variant.stock_account).first.credit

  end

  private

    def fix_preferences
      Preference.set! :currency, :EUR
    end
end