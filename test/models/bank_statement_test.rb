# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2020 Ekylibre SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: bank_statements
#
#  accounted_at           :datetime
#  cash_id                :integer          not null
#  created_at             :datetime         not null
#  creator_id             :integer
#  credit                 :decimal(19, 4)   default(0.0), not null
#  currency               :string           not null
#  custom_fields          :jsonb
#  debit                  :decimal(19, 4)   default(0.0), not null
#  id                     :integer          not null, primary key
#  initial_balance_credit :decimal(19, 4)   default(0.0), not null
#  initial_balance_debit  :decimal(19, 4)   default(0.0), not null
#  journal_entry_id       :integer
#  lock_version           :integer          default(0), not null
#  number                 :string           not null
#  started_on             :date             not null
#  stopped_on             :date             not null
#  updated_at             :datetime         not null
#  updater_id             :integer
#

require 'test_helper'

class BankStatementTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions

  test 'the validity of bank statements' do
    bank_statement = bank_statements(:bank_statements_001)
    assert bank_statement.valid?, inspect_errors(bank_statement)
    bank_statement.initial_balance_debit = 5
    bank_statement.initial_balance_credit = 5
    assert !bank_statement.valid?, inspect_errors(bank_statement)
  end

  test 'debit, credit and currency are computed during validations' do
    bank_statement = bank_statements(:bank_statements_001)
    bank_statement.debit = 0
    bank_statement.credit = 0
    bank_statement.currency = nil
    bank_statement.valid?
    assert_equal bank_statement.items.sum(:debit), bank_statement.debit
    assert_equal bank_statement.items.sum(:credit), bank_statement.credit
    assert_equal bank_statement.cash.currency, bank_statement.currency
  end

  test 'initial_balance_debit and initial_balance_credit are set to 0 on validations when nil' do
    bank_statement = bank_statements(:bank_statements_001)
    bank_statement.initial_balance_debit = nil
    bank_statement.initial_balance_credit = nil
    bank_statement.valid?
    assert_equal 0.0, bank_statement.initial_balance_debit
    assert_equal 0.0, bank_statement.initial_balance_credit
  end

  test 'save with items replace its items with the new items attributes' do
    bank_statement = bank_statements(:bank_statements_005)
    new_items = [
      {
        name: 'Bank statement item 1',
        credit: 15.3,
        debit: nil,
        letter: 'E',
        transfered_on: Date.parse('2016-05-11'),
        transaction_number: '119X6731'
      }, {
        name: 'Bank statement item 2',
        credit: nil,
        debit: 12.14,
        letter: 'F',
        transfered_on: Date.parse('2016-05-12'),
        transaction_number: '119X6734'
      }
    ]

    assert bank_statement.save_with_items(new_items), inspect_errors(bank_statement)
    assert_equal new_items.length, bank_statement.items.count

    new_items.each do |item_attributes|
      item = bank_statement.items.detect { |i| i.name == item_attributes[:name] }
      assert item.present?
      assert_equal item_attributes[:credit], item.credit
      assert_equal item_attributes[:debit], item.debit
      assert_equal item_attributes[:currency], item.currency
      assert_equal item_attributes[:letter], item.letter
      assert_equal item_attributes[:transfered_on], item.transfered_on
      assert_equal item_attributes[:transaction_number], item.transaction_number
    end
  end

  test 'save with items does not update items or bank statement when an item is invalid' do
    bank_statement = bank_statements(:bank_statements_001)
    bank_statement_item_names = bank_statement.items.map(&:name)
    new_invalid_items = [
      { name: nil,
        credit: 15.3,
        debit: nil,
        transfered_on: Date.parse('2016-05-11') }
    ]
    assert !bank_statement.save_with_items(new_invalid_items), inspect_errors(bank_statement)
    bank_statement.reload
    assert_equal bank_statement_item_names.to_set, bank_statement.items.map(&:name).to_set
  end

  test 'save with items removes the journal entry items bank statement and letter when previous items are removed' do
    bank_statement = bank_statements(:bank_statements_001)
    previous_jeis = bank_statement.items.map { |bsi| bsi.associated_journal_entry_items.to_a }.flatten
    assert bank_statement.save_with_items([]), inspect_errors(bank_statement)
    assert_equal 0, bank_statement.items.count
    previous_jeis.each do |jei|
      jei.reload
      assert jei.bank_statement_id.nil? && jei.bank_statement_letter.nil?
    end
  end

  test 'save with items keeps the journal entry items bank statement letter when previous items are kept' do
    bank_statement = bank_statements(:bank_statements_001)
    jeis_to_keep = bank_statement.items.detect { |item| item.letter == 'F' }.associated_journal_entry_items.to_a
    assert jeis_to_keep.any?
    new_items = [
      {
        name: 'Bank statement item 1',
        credit: 15.3,
        debit: nil,
        letter: 'F',
        transfered_on: Date.parse('2009-07-12'),
        transaction_number: '119X6731'
      }
    ]
    assert bank_statement.save_with_items(new_items), inspect_errors(bank_statement)
    jeis_to_keep.each do |jei|
      jei.reload
      assert_equal 'F', jei.bank_statement_letter
      assert_equal bank_statement.id, jei.bank_statement_id
    end
  end

  test 'eligible journal entry items includes journal entry items pointed by the bank statement and unpointed around bank statement range with same account' do
    bank_statement = bank_statements(:bank_statements_006)

    pointed = JournalEntryItem.pointed_by(bank_statement)
    assert pointed.any?

    unpointed_in_range = JournalEntryItem.where(account_id: bank_statement.cash_account_id).unpointed.between(bank_statement.started_on, bank_statement.stopped_on)
    assert unpointed_in_range.any?

    unpointed_around_started_on = JournalEntryItem.where(account_id: bank_statement.cash_account_id).unpointed.between(bank_statement.started_on - 20.days, bank_statement.started_on)
    unpointed_around_stopped_on = JournalEntryItem.where(account_id: bank_statement.cash_account_id).unpointed.between(bank_statement.stopped_on, bank_statement.stopped_on + 20.days)
    unpointed_around_range = unpointed_around_started_on + unpointed_around_stopped_on
    assert unpointed_around_range.any?

    eligible_journal_entry_item_ids = bank_statement.eligible_journal_entry_items.to_a.map(&:id)
    assert eligible_journal_entry_item_ids.any?
    assert pointed.all? { |jei| eligible_journal_entry_item_ids.include?(jei.id) }
    assert unpointed_in_range.all? { |jei| eligible_journal_entry_item_ids.include?(jei.id) }
    assert unpointed_around_range.all? { |jei| eligible_journal_entry_item_ids.include?(jei.id) }
  end

  test 'suspense process' do
    now = Time.new(2016, 11, 17, 19)
    currency = FinancialYear.at(now).currency

    main = Account.find_or_create_by_number('512INR01')
    assert main
    suspense = Account.find_or_create_by_number('511INR01')
    assert suspense

    client = Entity.normal.order(:id).where(client: true).first

    cash = Cash.create!(
      name: 'Namaste Bank',
      nature: :bank_account,
      currency: currency,
      main_account: main,
      suspend_until_reconciliation: true,
      suspense_account: suspense,
      journal: Journal.find_or_create_by!(nature: :bank, currency: currency, name: 'Namaste', code: 'Nam')
    )
    assert_equal 0, cash.main_account.totals[:balance]

    mode = IncomingPaymentMode.create!(
      name: 'Check on Namaste',
      cash: cash,
      with_accounting: true
    )

    payment = IncomingPayment.create!(
      to_bank_at: now - 1.hour,
      paid_at: now - 5.days,
      received: true,
      payer: client,
      amount: 248_600,
      mode: mode
    )
    cash.reload
    assert_equal 0, cash.main_account.totals[:balance]
    assert_equal 1, cash.journal_entry_items.count, cash.journal_entry_items.map(&:attributes).to_yaml.yellow
    Rails.logger.info ('%' * 80).yellow + cash.account.inspect.red + BankStatement.pluck(:journal_entry_id).inspect.green
    assert_equal 1, cash.unpointed_journal_entry_items.count, cash.journal_entry_items.map(&:attributes).to_yaml.yellow

    journal_entry = payment.journal_entry
    assert journal_entry.present?, payment.inspect
    assert_equal Date.civil(2016, 11, 17), journal_entry.printed_on
    assert_equal 1, journal_entry.items.where(account: suspense).count, journal_entry.inspect
    assert_equal 248_600, journal_entry.items.where(account: suspense).sum(:real_debit)

    bank_statement = BankStatement.create!(
      cash: cash,
      number: 'NB201611',
      started_on: '2016-11-01',
      stopped_on: '2016-11-30',
      items_attributes: [
        {
          transfered_on: '2016-11-25',
          name: 'Check #856124',
          credit: 248_600
        },
        {
          transfered_on: '2016-11-15',
          name: 'Bla bla bla',
          debit: 17_500.50
        }
      ]
    )
    assert bank_statement.valid?
    assert bank_statement.journal_entry.present?

    cash.reload

    Rails.logger.info ('#' * 80).red
    assert_equal 1, cash.unpointed_journal_entry_items.count, cash.journal_entry_items.map(&:attributes).to_yaml.yellow
    assert_equal 1, bank_statement.eligible_journal_entry_items.count
    item = cash.unpointed_journal_entry_items.first
    assert_equal journal_entry, item.entry

    assert_equal bank_statement.balance_credit, cash.main_account.totals[:balance_debit]
  end

  test 'ensure sign of amount is different in Incoming and Outgoing payments' do
    assert_equal 0, IncomingPayment.sign_of_amount + PurchasePayment.sign_of_amount
  end

  test 'delete bank statement delete journal entry' do
    now = Time.new(2016, 11, 17, 19)
    currency = FinancialYear.at(now).currency
    main = Account.find_or_create_by_number('512INR01')
    suspense = Account.find_or_create_by_number('511INR01')
    client = Entity.normal.order(:id).where(client: true).first

    cash = Cash.create!(
      name: 'Namaste Bank',
      nature: :bank_account,
      currency: currency,
      main_account: main,
      suspend_until_reconciliation: true,
      suspense_account: suspense,
      journal: Journal.find_or_create_by!(nature: :bank, currency: currency, name: 'Namaste', code: 'Nam')
    )
    assert_equal 0, cash.main_account.totals[:balance]

    mode = IncomingPaymentMode.create!(
      name: 'Check on Namaste',
      cash: cash,
      with_accounting: true
    )

    payment = IncomingPayment.create!(
      to_bank_at: now - 1.hour,
      paid_at: now - 5.days,
      received: true,
      payer: client,
      amount: 248_600,
      mode: mode
    )
    cash.reload
    assert_equal 0, cash.main_account.totals[:balance]
    assert_equal 1, cash.journal_entry_items.count, cash.journal_entry_items.map(&:attributes).to_yaml.yellow
    Rails.logger.info ('%' * 80).yellow + cash.account.inspect.red + BankStatement.pluck(:journal_entry_id).inspect.green
    assert_equal 1, cash.unpointed_journal_entry_items.count, cash.journal_entry_items.map(&:attributes).to_yaml.yellow

    journal_entry = payment.journal_entry
    assert journal_entry.present?, payment.inspect
    assert_equal Date.civil(2016, 11, 17), journal_entry.printed_on
    assert_equal 1, journal_entry.items.where(account: suspense).count, journal_entry.inspect
    assert_equal 248_600, journal_entry.items.where(account: suspense).sum(:real_debit)

    bank_statement = BankStatement.create!(
      cash: cash,
      number: 'NB201611',
      started_on: '2016-11-01',
      stopped_on: '2016-11-30',
      items_attributes: [
        {
          transfered_on: '2016-11-25',
          name: 'Check #856124',
          credit: 248_600
        },
        {
          transfered_on: '2016-11-15',
          name: 'Bla bla bla',
          debit: 17_500.50
        }
      ]
    )
    assert bank_statement.valid?
    assert bank_statement.journal_entry.present?

    journal_entry = bank_statement.journal_entry

    journal_entries_count = journal_entry.journal.entries.count
    bank_statement.destroy
    new_journal_entries_count = journal_entry.journal.entries.count

    assert_equal journal_entries_count + 1, new_journal_entries_count
  end

  [IncomingPayment, PurchasePayment].each do |payment|
    test "#{payment} can be lettered with bank_statement_items" do
      @payment_class = payment
      setup_data
      assert_lettered_by @payment.letter_with(@tanks), with_letters: %w[A]
    end

    test "#{payment} cannot be lettered when amounts don't match" do
      @payment_class = payment
      setup_data(amount_mismatch: true)
      assert_not_lettered_by @payment.letter_with(@tanks)
    end

    test "#{payment} cannot be lettered when the payment doesn't have any journal entry" do
      @payment_class = payment
      setup_data(no_journal_entry: true)
      assert_not_lettered_by @payment.letter_with(@tanks)
    end

    test "#{payment} cannot be lettered when the cashes don't match" do
      @payment_class = payment
      setup_data(cash_mismatch: true)
      assert_not_lettered_by @payment.letter_with(@tanks)
    end

    test "#{payment} cannot be lettered without any bank statement items" do
      @payment_class = payment
      setup_data
      assert_not_lettered_by @payment.letter_with([])
    end
  end

  def assert_lettered_by(operation, with_letters: ['A'])
    assert operation
    assert_equal with_letters,
                 @payment.journal_entry.items.pluck(:bank_statement_letter).uniq.compact
    assert_equal with_letters,
                 @tanks.each(&:reload).map(&:letter).uniq
  end

  def assert_not_lettered_by(operation)
    refute operation
    if @payment.journal_entry
      assert_empty @payment.journal_entry.items.pluck(:bank_statement_letter).uniq.compact
    end
    assert_empty @tanks.map(&:letter).uniq.compact
  end

  def wipe_db
    [Payslip, PayslipNature, InventoryItem, Inventory, Journal, Account, Cash, BankStatement, BankStatementItem,
     OutgoingPayment, Entity, IncomingPayment, IncomingPaymentMode, OutgoingPaymentMode]
      .each &:delete_all
  end

  def setup_data(**options)
    wipe_db

    ::Preference.set!(:bookkeep_automatically, options[:no_journal_entry].blank?)
    journal = Journal.create!(name: 'Record')
    fuel_act = Account.create!(name: 'Fuel', number: '102')
    caps_act = Account.create!(name: 'Caps', number: '101')

    @warrig_tank = Cash.create!(journal: journal, main_account: fuel_act, name: 'War-rig\'s Tank')
    @caps_stash = Cash.create!(journal: journal, main_account: caps_act, name: 'Stash o\' Caps')

    setup_items(options[:amount_mismatch] ? 1336 : 1337)
    setup_payment(options[:cash_mismatch])
  end

  def setup_items(amount)
    amount_attr = (@payment_class == IncomingPayment ? :credit : :debit)

    now = Time.zone.now
    fuel_level = BankStatement.create!(
      currency: 'EUR',
      number: 'Fuel level check',
      started_on: now - 10.days,
      stopped_on: now,
      cash: @warrig_tank
    )

    @tanks = []
    @tanks << BankStatementItem.create!(
      name: 'Main tank',
      bank_statement: fuel_level,
      transfered_on: now - 5.days,
      amount_attr => 42
    )

    @tanks << BankStatementItem.create!(
      name: 'Backup tank',
      bank_statement: fuel_level,
      transfered_on: now - 5.days,
      amount_attr => amount
    )
  end

  def setup_payment(cash_match)
    cash = cash_match ? @caps_stash : @warrig_tank

    Account.create!(name: 'Citadel', number: '106')

    diesel = "#{@payment_class == IncomingPayment ? 'Incoming' : 'Outgoing'}PaymentMode".constantize.create!(cash: cash, with_accounting: true, name: 'Diesel')
    max = Entity.create!(first_name: 'Max', last_name: 'Rockatansky', nature: :contact)
    @payment = @payment_class.create!(amount: 1379, currency: 'EUR', @payment_class.third_attribute => max, mode: diesel, responsible: User.first, to_bank_at: Time.zone.now - 5.days)
  end

  def inspect_errors(object)
    [object.inspect,
     object.errors.full_messages.to_sentence,
     object.items.map { |i| [' - ' + i.inspect, '    - ' + i.errors.full_messages.to_sentence] }].join("\n")
  end
end
