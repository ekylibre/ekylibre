# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2016 Brice Texier, David Joulin
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
#  lock_version           :integer          default(0), not null
#  number                 :string           not null
#  started_on             :date             not null
#  stopped_on             :date             not null
#  updated_at             :datetime         not null
#  updater_id             :integer
#

require 'test_helper'

class BankStatementTest < ActiveSupport::TestCase
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
    bank_statement = bank_statements(:bank_statements_001)

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

  def inspect_errors(object)
    [object.inspect,
     object.errors.full_messages.to_sentence,
     object.items.map { |i| [' - ' + i.inspect, '    - ' + i.errors.full_messages.to_sentence] }].join("\n")
  end
end
