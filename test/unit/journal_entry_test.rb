# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2010 Brice Texier, Thibaud Mérigon
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
# == Table: journal_entries
#
#  account_id        :integer          not null
#  bank_statement_id :integer          
#  closed            :boolean          not null
#  comment           :text             
#  company_id        :integer          not null
#  created_at        :datetime         not null
#  creator_id        :integer          
#  credit            :decimal(16, 2)   default(0.0), not null
#  currency_credit   :decimal(16, 2)   default(0.0), not null
#  currency_debit    :decimal(16, 2)   default(0.0), not null
#  debit             :decimal(16, 2)   default(0.0), not null
#  draft             :boolean          not null
#  expired_on        :date             
#  id                :integer          not null, primary key
#  journal_id        :integer          
#  letter            :string(8)        
#  lock_version      :integer          default(0), not null
#  name              :string(255)      not null
#  position          :integer          
#  record_id         :integer          not null
#  updated_at        :datetime         not null
#  updater_id        :integer          
#

require 'test_helper'

class JournalEntryTest < ActiveSupport::TestCase

  fixtures :journal_entries

  test "the validity of entries" do
    journal_entry = journal_entries(:journal_entries_001)
    assert journal_entry.valid?, journal_entry.inspect+"\n"+journal_entry.errors.full_messages.to_sentence
    journal_entry.currency_debit = 5
    assert journal_entry.valid?, journal_entry.inspect+"\n"+journal_entry.errors.full_messages.to_sentence
    journal_entry.currency_credit = 17
    assert !journal_entry.valid?, journal_entry.inspect+"\n"+journal_entry.errors.full_messages.to_sentence
    journal_entry.currency_debit = 0
    assert journal_entry.valid?, journal_entry.inspect+"\n"+journal_entry.errors.full_messages.to_sentence
  end

end
