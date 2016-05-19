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
# == Table: journal_entry_items
#
#  absolute_credit           :decimal(19, 4)   default(0.0), not null
#  absolute_currency         :string           not null
#  absolute_debit            :decimal(19, 4)   default(0.0), not null
#  account_id                :integer          not null
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
#  financial_year_id         :integer          not null
#  id                        :integer          not null, primary key
#  journal_id                :integer          not null
#  letter                    :string
#  lock_version              :integer          default(0), not null
#  name                      :string           not null
#  position                  :integer
#  printed_on                :date             not null
#  real_balance              :decimal(19, 4)   default(0.0), not null
#  real_credit               :decimal(19, 4)   default(0.0), not null
#  real_currency             :string           not null
#  real_currency_rate        :decimal(19, 10)  default(0.0), not null
#  real_debit                :decimal(19, 4)   default(0.0), not null
#  state                     :string           not null
#  updated_at                :datetime         not null
#  updater_id                :integer
#

require 'test_helper'

class JournalEntryItemTest < ActiveSupport::TestCase
  test_model_actions
  test 'the validity of entries' do
    item = journal_entry_items(:journal_entry_items_001)
    assert item.valid?, item.inspect + "\n" + item.errors.full_messages.to_sentence
    item.real_debit = 5
    assert item.valid?, item.inspect + "\n" + item.errors.full_messages.to_sentence
    item.real_credit = 17
    assert !item.valid?, item.inspect + "\n" + item.errors.full_messages.to_sentence
    item.real_debit = 0
    assert item.valid?, item.inspect + "\n" + item.errors.full_messages.to_sentence
  end
  test "journal entry items pointed by a bank statement" do
    bank_statement = bank_statements(:bank_statements_001)
    pointed_ids_by_bank_statement = [
      journal_entry_items(:journal_entry_items_037),
      journal_entry_items(:journal_entry_items_039),
      journal_entry_items(:journal_entry_items_053),
      journal_entry_items(:journal_entry_items_196)
    ].map(&:id)
    assert_equal pointed_ids_by_bank_statement.to_set, JournalEntryItem.pointed_by(bank_statement).map(&:id).to_set
  end
  test "destroy clears the bank statement items associated" do
    item = journal_entry_items(:journal_entry_items_011)
    bank_statement = item.bank_statement
    bank_statement_letter = item.bank_statement_letter
    assert bank_statement.present? && bank_statement_letter.present?
    associated_bank_statement_items = bank_statement.items.where(letter: bank_statement_letter).to_a
    assert associated_bank_statement_items.any?
    item.destroy
    associated_bank_statement_items.map &:reload
    assert associated_bank_statement_items.all? { |bsi| bsi.letter.nil? }
  end
  test "bank statement letter is set to nil on validations when blank" do
    item = journal_entry_items(:journal_entry_items_001)
    item.bank_statement_letter = " "
    assert item.valid?
    assert_nil item.bank_statement_letter
  end
end
