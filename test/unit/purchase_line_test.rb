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
# == Table: purchase_lines
#
#  account_id      :integer          not null
#  amount          :decimal(16, 2)   default(0.0), not null
#  annotation      :text             
#  company_id      :integer          not null
#  created_at      :datetime         not null
#  creator_id      :integer          
#  id              :integer          not null, primary key
#  lock_version    :integer          default(0), not null
#  position        :integer          
#  pretax_amount   :decimal(16, 2)   default(0.0), not null
#  price_id        :integer          not null
#  product_id      :integer          not null
#  purchase_id     :integer          not null
#  quantity        :decimal(16, 4)   default(1.0), not null
#  tracking_id     :integer          
#  tracking_serial :string(255)      
#  unit_id         :integer          not null
#  updated_at      :datetime         not null
#  updater_id      :integer          
#  warehouse_id    :integer          
#


require 'test_helper'

class PurchaseLineTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
