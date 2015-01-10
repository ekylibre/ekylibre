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
# == Table: warehouses
#
#  comment          :text             
#  company_id       :integer          not null
#  contact_id       :integer          
#  created_at       :datetime         not null
#  creator_id       :integer          
#  establishment_id :integer          
#  id               :integer          not null, primary key
#  lock_version     :integer          default(0), not null
#  name             :string(255)      not null
#  number           :integer          
#  parent_id        :integer          
#  product_id       :integer          
#  quantity_max     :decimal(16, 4)   
#  reservoir        :boolean          
#  unit_id          :integer          
#  updated_at       :datetime         not null
#  updater_id       :integer          
#  x                :string(255)      
#  y                :string(255)      
#  z                :string(255)      
#


require 'test_helper'

class WarehouseTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
