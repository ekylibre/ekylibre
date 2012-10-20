# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2012 Brice Texier, Thibaud Merigon
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
#  balance                :decimal(19, 4)   default(0.0), not null
#  created_at             :datetime         not null
#  created_on             :date             not null
#  creator_id             :integer          
#  credit                 :decimal(19, 4)   default(0.0), not null
#  debit                  :decimal(19, 4)   default(0.0), not null
#  financial_year_id      :integer          
#  id                     :integer          not null, primary key
#  journal_id             :integer          not null
#  lock_version           :integer          default(0), not null
#  number                 :string(255)      not null
#  original_credit        :decimal(19, 4)   default(0.0), not null
#  original_currency      :string(3)        
#  original_currency_rate :decimal(19, 10)  default(0.0), not null
#  original_debit         :decimal(19, 4)   default(0.0), not null
#  printed_on             :date             not null
#  resource_id            :integer          
#  resource_type          :string(255)      
#  state                  :string(32)       default("draft"), not null
#  updated_at             :datetime         not null
#  updater_id             :integer          
#


require 'test_helper'

class JournalEntryTest < ActiveSupport::TestCase

  context "A journal" do

    should "forbids to write records before its closure date" do
      @journal = journals(:journals_001)
      assert_raise ActiveRecord::RecordInvalid do
        record = @journal.entries.create!(:printed_on=>@journal.closed_on-10)
      end
      assert_nothing_raised do
        record = @journal.entries.create!(:printed_on=>@journal.closed_on+1)
      end
    end
    
  end

end
