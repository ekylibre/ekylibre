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
# == Table: bank_statement_items
#
#  accounted_at       :datetime
#  bank_statement_id  :integer          not null
#  created_at         :datetime         not null
#  creator_id         :integer
#  credit             :decimal(19, 4)   default(0.0), not null
#  currency           :string           not null
#  debit              :decimal(19, 4)   default(0.0), not null
#  id                 :integer          not null, primary key
#  initiated_on       :date
#  journal_entry_id   :integer
#  letter             :string
#  lock_version       :integer          default(0), not null
#  memo               :string
#  name               :string           not null
#  transaction_number :string
#  transfered_on      :date             not null
#  updated_at         :datetime         not null
#  updater_id         :integer
#
require 'test_helper'

class BankStatementItemTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions

  test 'the validity of bank statement items' do
    item = bank_statement_items(:bank_statement_items_001)
    assert item.valid?, inspect_errors(item)
    item.credit = 5
    assert item.valid?, inspect_errors(item)
    item.debit = 17
    assert !item.valid?, inspect_errors(item)
    item.debit = 0
    assert item.valid?, inspect_errors(item)
    item.credit = 0
    assert !item.valid?, inspect_errors(item)
  end

  test 'currency is set on validations from the bank statement' do
    item = bank_statement_items(:bank_statement_items_001)
    item.currency = nil
    assert item.valid?, inspect_errors(item)
    assert_equal item.bank_statement.currency, item.currency
  end

  test 'debit or credit is set to 0 on validations when nil' do
    item = bank_statement_items(:bank_statement_items_001)
    item.credit = 15.3
    item.debit = nil
    assert item.valid?, inspect_errors(item)
    assert_equal 0.0, item.debit
    item.credit = nil
    item.debit = 15.3
    assert item.valid?, inspect_errors(item)
    assert_equal 0.0, item.credit
  end

  test 'letter is set to nil on validations when blank' do
    item = bank_statement_items(:bank_statement_items_001)
    item.letter = ' '
    assert item.valid?, inspect_errors(item)
    assert_nil item.letter
  end

  test 'destroy clears the journal entry items associated' do
    bsi = bank_statement_items(:bank_statement_items_002)
    jeis = JournalEntryItem.pointed_by_with_letter(bsi.bank_statement, bsi.letter)
    assert jeis.any?
    bsi.destroy
    assert jeis.all? { |jei| jei.bank_statement_letter.nil? && jei.bank_statement_id.nil? }
  end

  def inspect_errors(object)
    object.inspect + "\n" + object.errors.full_messages.to_sentence
  end
end
