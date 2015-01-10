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
# == Table: stock_moves
#
#  comment      :text             
#  company_id   :integer          not null
#  created_at   :datetime         not null
#  creator_id   :integer          
#  generated    :boolean          not null
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  moved_on     :date             
#  name         :string(255)      not null
#  origin_id    :integer          
#  origin_type  :string(255)      
#  planned_on   :date             not null
#  product_id   :integer          not null
#  quantity     :decimal(16, 4)   not null
#  stock_id     :integer          
#  tracking_id  :integer          
#  unit_id      :integer          not null
#  updated_at   :datetime         not null
#  updater_id   :integer          
#  virtual      :boolean          not null
#  warehouse_id :integer          not null
#


require 'test_helper'

class StockMoveTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
