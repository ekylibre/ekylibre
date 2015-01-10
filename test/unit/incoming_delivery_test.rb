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
# == Table: incoming_deliveries
#
#  amount           :decimal(16, 2)   default(0.0), not null
#  comment          :text             
#  company_id       :integer          not null
#  contact_id       :integer          
#  created_at       :datetime         not null
#  creator_id       :integer          
#  currency_id      :integer          
#  id               :integer          not null, primary key
#  lock_version     :integer          default(0), not null
#  mode_id          :integer          
#  moved_on         :date             
#  number           :string(255)      
#  planned_on       :date             
#  pretax_amount    :decimal(16, 2)   default(0.0), not null
#  purchase_id      :integer          
#  reference_number :string(255)      
#  updated_at       :datetime         not null
#  updater_id       :integer          
#  weight           :decimal(16, 4)   
#


require 'test_helper'

class IncomingDeliveryTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
