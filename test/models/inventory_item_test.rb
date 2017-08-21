# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2017 Brice Texier, David Joulin
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
# == Table: inventory_items
#
#  actual_population        :decimal(19, 4)   not null
#  created_at               :datetime         not null
#  creator_id               :integer
#  currency                 :string
#  expected_population      :decimal(19, 4)   not null
#  id                       :integer          not null, primary key
#  inventory_id             :integer          not null
#  lock_version             :integer          default(0), not null
#  product_id               :integer          not null
#  product_movement_id      :integer
#  unit_pretax_stock_amount :decimal(19, 4)   default(0.0), not null
#  updated_at               :datetime         not null
#  updater_id               :integer
#

require 'test_helper'

class InventoryItemTest < ActiveSupport::TestCase
  test_model_actions

  test 'method average_cost_amount' do
    item = InventoryItem.new(
      actual_population: 10.0,
      creator_id: 1,
      expected_population: 15.0,
      inventory_id: 1,
      lock_version: 0,
      product_id: 65,
      unit_pretax_stock_amount: 0.0,
      updater_id: 1
      )

    refute_nil item.send(:compute_average_cost_amount)
    assert item.send(:compute_average_cost_amount)
  end
end
