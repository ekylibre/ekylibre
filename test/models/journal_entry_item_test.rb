# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2018 Brice Texier, David Joulin
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
# == Table: journal_entry_items
#
#  absolute_credit           :decimal(19, 4)   default(0.0), not null
#  absolute_currency         :string           not null
#  absolute_debit            :decimal(19, 4)   default(0.0), not null
#  absolute_pretax_amount    :decimal(19, 4)   default(0.0), not null
#  account_id                :integer          not null
#  activity_budget_id        :integer
#  balance                   :decimal(19, 4)   default(0.0), not null
#  bank_statement_id         :integer
#  bank_statement_letter     :string
#  created_at                :datetime         not null
#  creator_id                :integer
#  credit                    :decimal(19, 4)   default(0.0), not null
#  cumulated_absolute_credit :decimal(19, 4)   default(0.0), not null
#  cumulated_absolute_debit  :decimal(19, 4)   default(0.0), not null
#  currency                  :string           not null
#  debit                     :decimal(19, 4)   default(0.0), not null
#  description               :text
#  entry_id                  :integer          not null
#  entry_number              :string           not null
#  equipment_id              :integer
#  financial_year_id         :integer          not null
#  id                        :integer          not null, primary key
#  journal_id                :integer          not null
#  letter                    :string
#  lock_version              :integer          default(0), not null
#  name                      :string           not null
#  position                  :integer
#  pretax_amount             :decimal(19, 4)   default(0.0), not null
#  printed_on                :date             not null
#  project_budget_id         :integer
#  real_balance              :decimal(19, 4)   default(0.0), not null
#  real_credit               :decimal(19, 4)   default(0.0), not null
#  real_currency             :string           not null
#  real_currency_rate        :decimal(19, 10)  default(0.0), not null
#  real_debit                :decimal(19, 4)   default(0.0), not null
#  real_pretax_amount        :decimal(19, 4)   default(0.0), not null
#  resource_id               :integer
#  resource_prism            :string
#  resource_type             :string
#  state                     :string           not null
#  tax_declaration_item_id   :integer
#  tax_declaration_mode      :string
#  tax_id                    :integer
#  team_id                   :integer
#  updated_at                :datetime         not null
#  updater_id                :integer
#  variant_id                :integer
#

require 'test_helper'

class JournalEntryItemTest < ActiveSupport::TestCase
  test_model_actions

  test 'the validity of entries' do
    item = JournalEntryItem.where(state: :draft).where('real_debit > 0').first
    assert item.valid?, item.inspect + "\n" + item.errors.full_messages.to_sentence
    item.real_debit += 5
    assert item.valid?, item.inspect + "\n" + item.errors.full_messages.to_sentence
    item.real_credit += 17
    assert !item.valid?, item.inspect + "\n" + item.errors.full_messages.to_sentence
    item.real_debit = 0
    assert item.valid?, item.inspect + "\n" + item.errors.full_messages.to_sentence
  end

  test 'classical case' do
    journal = Journal.where(currency: Preference[:currency]).first
    entry = JournalEntry.new(
      journal: journal,
      printed_on: Time.zone.today,
      items: [
        JournalEntryItem.new(account: Account.first, real_debit: 125, real_credit: 0, name: 'Yeah!'),
        JournalEntryItem.new(account: Account.second, real_debit: 0, real_credit: 125, name: 'Yeah!')
      ]
    )
    assert entry.save, entry.errors.inspect
    entry.items.each do |item|
      assert item.real_debit, item.debit
      assert item.real_credit, item.credit
    end
  end

  test 'lettering is indicated as partial (*) when lettered items are not balanced' do
    first_account = Account.create!(name: 'First account', number: '123FIRST')
    random_account = Account.create!(name: 'Random account', number: '123RANDOM')
    other_random = Account.create!(name: 'Random account bis', number: '123RANBIS')
    journal = Journal.create!(name: 'Test journal JEI', code: 'JEITEST', currency: 'EUR')
    entry = JournalEntry.create!(journal: journal, currency: 'EUR', printed_on: Date.today, items_attributes:
      [{ account: first_account, name: 'Hello', real_debit: 10, letter: 'A' },
       { account: random_account, name: 'Is it me', real_credit: 10 }])
    assert_equal 'A*', entry.items.find_by(real_debit: 10).letter

    entry.items.find_by(real_debit: 10).update_column(:letter, 'A')
    assert_equal 'A*', entry.items.reload.find_by(real_debit: 10).letter

    to_letter_with = JournalEntry.create!(
      journal: journal,
      currency: 'EUR',
      printed_on: Date.today,
      items_attributes:
        [{ account: random_account, name: 'You\'re', real_debit: 10 },
         { account: first_account, name: 'Looking for?', real_credit: 10, letter: 'A' }]
    )
    assert_equal 'A', entry.items.find_by(real_debit: 10).letter
    assert_equal 'A', to_letter_with.items.find_by(real_credit: 10).letter

    entry.items.find_by(real_debit: 10).update(real_debit: 11)
    assert_equal 'A*', entry.items.find_by(real_debit: 11).letter
    assert_equal 'A*', to_letter_with.items.find_by(real_credit: 10).letter

    entry.items.find_by(real_debit: 11).update(real_debit: 10)
    assert_equal 'A', entry.items.find_by(real_debit: 10).letter
    assert_equal 'A', to_letter_with.items.find_by(real_credit: 10).letter

    entry.items.find_by(real_debit: 10).update(letter: nil)
    assert_equal 'A*', to_letter_with.items.find_by(real_credit: 10).letter

    entry.items.find_by(real_debit: 10).update(letter: 'A')
    assert_equal 'A', to_letter_with.items.find_by(real_credit: 10).letter

    entry.items.find_by(real_debit: 10).update(letter: 'B')
    assert_equal 'A*', to_letter_with.items.find_by(real_credit: 10).letter

    entry.items.find_by(real_debit: 10).update(letter: 'A')
    assert_equal 'A', entry.items.find_by(real_debit: 10).letter
    assert_equal 'A', to_letter_with.items.find_by(real_credit: 10).letter

    entry.items.find_by(real_debit: 10).update(account: other_random)
    assert_equal 'A*', to_letter_with.items.find_by(real_credit: 10).letter
    assert_nil entry.items.find_by(real_debit: 10).letter
  end

  # Test case when debit and credit are invalid
  test 'both filled debit and credit' do
    journal = Journal.where(currency: Preference[:currency]).first
    entry = JournalEntry.new(
      journal: journal,
      printed_on: Time.zone.today,
      items: [
        JournalEntryItem.new(account: Account.first, real_debit: 125, real_credit: 20, name: 'Yeah!'),
        JournalEntryItem.new(account: Account.second, real_debit: 20, real_credit: 125, name: 'Yeah!')
      ]
    )
    assert !entry.save, entry.inspect + ":\n - " + entry.items.map(&:inspect).join("\n - ")
  end

  test 'journal entry items pointed by a bank statement' do
    bank_statement = bank_statements(:bank_statements_002)
    pointed_ids_by_bank_statement = [
      journal_entry_items(:journal_entry_items_011),
      journal_entry_items(:journal_entry_items_014),
      journal_entry_items(:journal_entry_items_028),
      journal_entry_items(:journal_entry_items_031),
      journal_entry_items(:journal_entry_items_037)
    ].map(&:id)
    assert_equal pointed_ids_by_bank_statement.to_set, JournalEntryItem.pointed_by(bank_statement).map(&:id).to_set
  end

  test 'destroy clears the bank statement items associated' do
    item = JournalEntryItem.joins(:bank_statement).where.not(bank_statement_letter: nil, bank_statements: { number: nil }).where(state: :draft).first
    assert item, 'Cannot find a non-closed bank-statement-linked journal entry item'
    bank_statement = item.bank_statement
    bank_statement_letter = item.bank_statement_letter
    assert bank_statement.present? && bank_statement_letter.present?
    associated_bank_statement_items = bank_statement.items.where(letter: bank_statement_letter).to_a
    assert associated_bank_statement_items.any?
    item.destroy
    associated_bank_statement_items.map(&:reload)
    assert associated_bank_statement_items.all? { |bsi| bsi.letter.nil? }
  end

  test 'bank statement letter is set to nil on validations when blank' do
    item = JournalEntryItem.joins(:bank_statement).where.not(bank_statement_letter: nil, bank_statements: { number: nil }).where(state: :draft).first
    item.bank_statement_letter = ' '
    assert item.valid?, item.errors.full_messages.to_sentence
    assert_nil item.bank_statement_letter
  end

  test 'third party is the account client when the account has one client but neither supplier nor employee' do
    account = create(:account)
    client = create(:entity, client_account_id: account.id)
    item = create(:journal_entry_item, account: account, financial_year: financial_years(:financial_years_025))
    assert_equal item.third_party, client
  end

  test 'third party is the account supplier when the account has one supplier but neither client nor employee' do
    account = create(:account)
    supplier = create(:entity, supplier_account_id: account.id)
    item = create(:journal_entry_item, account: account, financial_year: financial_years(:financial_years_025))
    assert_equal item.third_party, supplier
  end

  test 'third party is the account employee when the account has one employee but neither client nor supplier' do
    financial_year = financial_years(:financial_years_025)
    account = create(:account)
    employee = create(:entity, employee_account_id: account.id)
    item = create(:journal_entry_item, account: account, financial_year: financial_year)
    assert_equal item.third_party, employee
  end

  test 'third party is set when the account has client, supplier or employee but targets the same entity' do
    financial_year = financial_years(:financial_years_025)
    account = create(:account)
    client_employee_and_supplier = create(:entity, client_account_id: account.id, employee_account_id: account.id, supplier_account_id: account.id)
    item = create(:journal_entry_item, account: account, financial_year: financial_year)
    assert_equal item.third_party, client_employee_and_supplier
  end

  test 'third party is not set when the account has more than one client, supplier or employee' do
    financial_year = financial_years(:financial_years_025)
    account = create(:account)
    create(:entity, employee_account_id: account.id)
    create(:entity, client_account_id: account.id)
    item = create(:journal_entry_item, account: account, financial_year: financial_year)
    refute item.third_party
  end
end
