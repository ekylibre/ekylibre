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
# == Table: stock_transfers
#
#  comment              :text             
#  company_id           :integer          not null
#  created_at           :datetime         not null
#  creator_id           :integer          
#  id                   :integer          not null, primary key
#  lock_version         :integer          default(0), not null
#  moved_on             :date             
#  nature               :string(8)        not null
#  number               :string(64)       not null
#  planned_on           :date             not null
#  product_id           :integer          not null
#  quantity             :decimal(16, 4)   not null
#  second_stock_move_id :integer          
#  second_warehouse_id  :integer          
#  stock_move_id        :integer          
#  tracking_id          :integer          
#  unit_id              :integer          
#  updated_at           :datetime         not null
#  updater_id           :integer          
#  warehouse_id         :integer          not null
#


require 'test_helper'

class StockTransferTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
