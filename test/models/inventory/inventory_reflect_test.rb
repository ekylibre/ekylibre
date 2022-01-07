require 'test_helper'

class InventoryReflectTest < Ekylibre::Testing::ApplicationTestCase
  setup do
    fix_preferences

    @variant = ProductNatureVariant.import_from_lexicon('0_0_18')

    @fy = create :financial_year, year: 2018
    @catalog = create :catalog, usage: :stock
    @unit_pretax_amount = 10.0
    @initial_population = 10.0
    @catalog.items.create! variant: @variant, amount: @unit_pretax_amount, started_at: Date.new(2018, 1, 1)

    @product = create :matter, name: 'Engrais 0_0_18', variant: @variant
    create :journal, used_for_permanent_stock_inventory: true
  end

  test "Reflecting an inventory without previous stock initializes stock value and amount" do
    inventory = create :inventory, year: 2018, financial_year: @fy

    inventory.items.create! product: @product, expected_population: 0, actual_population: @initial_population
    inventory.reload
    inventory.reflect!

    assert inventory.reflected?
    assert inventory.journal_entry.present?

    assert_equal (@initial_population * @unit_pretax_amount), @variant.stock_account.journal_entry_items_calculate(:balance, @fy.started_on, @fy.stopped_on)
    assert_equal -(@initial_population * @unit_pretax_amount), @variant.stock_movement_account.journal_entry_items_calculate(:balance, @fy.started_on, @fy.stopped_on)
  end

  test "Reflecting an inventory with initial stock and no accountancy value creates the correct movement and journal_entry" do
    new_population = 20.0
    @product.update! initial_population: new_population
    inventory = create :inventory, year: 2018, financial_year: @fy

    inventory.items.create! product: @product, expected_population: new_population, actual_population: @initial_population
    inventory.reload
    inventory.reflect!

    assert inventory.reflected?
    assert inventory.journal_entry.present?

    assert_equal -(new_population - @initial_population), inventory.items.first.reload.product_movement.delta

    assert_equal (new_population - @initial_population) * @unit_pretax_amount, @variant.stock_account.journal_entry_items_calculate(:balance, @fy.started_on, @fy.stopped_on)
    assert_equal -((new_population - @initial_population) * @unit_pretax_amount), @variant.stock_movement_account.journal_entry_items_calculate(:balance, @fy.started_on, @fy.stopped_on)
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

  test "Reflecting update and reflecting an inventory with initial stock and initial accountancy amount creates the correct movement and journal entry" do
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

    # Update the same inventory (it must update the current entry and not adding one)
    inventory.items.first.update!(expected_population: 10, actual_population: 20)
    inventory.reload
    inventory.save!

    assert inventory.journal_entry.present?

    assert_equal 200.0.to_d, @variant.stock_account.journal_entry_items_calculate(:balance, @fy.started_on, @fy.stopped_on)

    # Inventory loss should be 0
    assert_equal 10.to_d, inventory.items.first.reload.product_movement.delta
    # Entry item of stock account should be credit: 100 as we record a loss of stock
    assert_equal 0.to_d, inventory.journal_entry.items.where(account: @variant.stock_account).first.credit
  end

  test "Reflecting two inventory at two different dates with initial stock and initial accountancy amount creates the correct movement and journal entry" do
    journal = create :journal, nature: :forward

    JournalEntry.create! journal: journal, financial_year: @fy, printed_on: @fy.started_on, items_attributes: [
      { real_debit: 200, name: "init stock", account: @variant.stock_account },
      { real_credit: 200, name: "init stock", account: Account.find_or_create_by_number("471") }
    ]

    first_inventory = create :inventory, year: 2018, day: 15, financial_year: @fy

    first_inventory.items.create! product: @product, expected_population: 20, actual_population: 10
    first_inventory.reload
    first_inventory.reflect!

    assert first_inventory.reflected?
    assert first_inventory.journal_entry.present?

    assert_equal 100.0.to_d, @variant.stock_account.journal_entry_items_calculate(:balance, @fy.started_on, @fy.stopped_on)
    # Debit in movement account is 100 here as its a loss of stock
    assert_equal 100.0.to_d, @variant.stock_movement_account.journal_entry_items_calculate(:debit, @fy.started_on, @fy.stopped_on)

    # Inventory loss should be 10
    assert_equal -10.to_d, first_inventory.items.first.reload.product_movement.delta
    # Entry item of stock account should be credit: 100 as we record a loss of stock
    assert_equal 100.to_d, first_inventory.journal_entry.items.where(account: @variant.stock_account).first.credit

    # Add inventory
    second_inventory = create :inventory, year: 2018, day: 25, financial_year: @fy

    second_inventory.items.create! product: @product, expected_population: 10, actual_population: 30
    second_inventory.reload
    second_inventory.reflect!

    assert second_inventory.reflected?
    assert second_inventory.journal_entry.present?

    assert_equal 300.0.to_d, @variant.stock_account.journal_entry_items_calculate(:balance, @fy.started_on, @fy.stopped_on)

    # Inventory loss should be 0
    assert_equal 20.to_d, second_inventory.items.first.reload.product_movement.delta
    # Entry item of stock account should be credit: 100 as we record a loss of stock
    assert_equal 200.to_d, second_inventory.journal_entry.items.where(account: @variant.stock_account).first.debit

    # delete first_inventory should not be allowed
    refute first_inventory.destroyable?
    refute first_inventory.updateable?

    # destroy second_inventory and have the right value
    assert second_inventory.destroyable?
    assert second_inventory.updateable?
    second_inventory.destroy!
    assert_equal 100.0.to_d, @variant.stock_account.journal_entry_items_calculate(:balance, @fy.started_on, @fy.stopped_on)

    # destroy first_inventory and have the right value
    assert first_inventory.destroyable?
    assert first_inventory.updateable?
    first_inventory.destroy!
    # must have the same value than before all inventories
    assert_equal 200.0.to_d, @variant.stock_account.journal_entry_items_calculate(:balance, @fy.started_on, @fy.stopped_on)
  end

  private

    def fix_preferences
      Preference.set! :currency, :EUR
      Preference.set! :language, :fra
      Preference.set! :country, :fr
      I18n.locale = :fra
    end
end
