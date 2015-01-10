# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2015 Brice Texier, Thibaud Merigon
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
# == Table: transfers
#
#  accounted_at     :datetime         
#  amount           :decimal(16, 2)   default(0.0), not null
#  comment          :string(255)      
#  company_id       :integer          not null
#  created_at       :datetime         not null
#  created_on       :date             
#  creator_id       :integer          
#  id               :integer          not null, primary key
#  journal_entry_id :integer          
#  label            :string(255)      
#  lock_version     :integer          default(0), not null
#  paid_amount      :decimal(16, 2)   default(0.0), not null
#  started_on       :date             
#  stopped_on       :date             
#  supplier_id      :integer          
#  updated_at       :datetime         not null
#  updater_id       :integer          
#


require 'test_helper'

class TransferTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
