# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2009-2012 Brice Texier, Thibaud Merigon
# Copyright (C) 2012-2014 Brice Texier, David Joulin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: journal_entry_items
#
#  absolute_credit           :decimal(19, 4)   default(0.0), not null
#  absolute_currency         :string(3)        not null
#  absolute_debit            :decimal(19, 4)   default(0.0), not null
#  account_id                :integer          not null
#  balance                   :decimal(19, 4)   default(0.0), not null
#  bank_statement_id         :integer
#  created_at                :datetime         not null
#  creator_id                :integer
#  credit                    :decimal(19, 4)   default(0.0), not null
#  cumulated_absolute_credit :decimal(19, 4)   default(0.0), not null
#  cumulated_absolute_debit  :decimal(19, 4)   default(0.0), not null
#  currency                  :string(3)        not null
#  debit                     :decimal(19, 4)   default(0.0), not null
#  description               :text
#  entry_id                  :integer          not null
#  entry_number              :string(255)      not null
#  financial_year_id         :integer          not null
#  id                        :integer          not null, primary key
#  journal_id                :integer          not null
#  letter                    :string(10)
#  lock_version              :integer          default(0), not null
#  name                      :string(255)      not null
#  position                  :integer
#  printed_at                :datetime         not null
#  real_credit               :decimal(19, 4)   default(0.0), not null
#  real_currency             :string(3)        not null
#  real_currency_rate        :decimal(19, 10)  default(0.0), not null
#  real_debit                :decimal(19, 4)   default(0.0), not null
#  state                     :string(30)       not null
#  updated_at                :datetime         not null
#  updater_id                :integer
#


require 'test_helper'

class JournalEntryItemTest < ActiveSupport::TestCase

  fixtures :journal_entry_items

  test "the validity of entries" do
    item = journal_entry_items(:journal_entry_items_001)
    assert item.valid?, item.inspect + "\n" + item.errors.full_messages.to_sentence
    item.real_debit = 5
    assert item.valid?, item.inspect + "\n" + item.errors.full_messages.to_sentence
    item.real_credit = 17
    assert !item.valid?, item.inspect + "\n" + item.errors.full_messages.to_sentence
    item.real_debit = 0
    assert item.valid?, item.inspect + "\n" + item.errors.full_messages.to_sentence
  end

end
