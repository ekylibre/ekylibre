# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2023 Ekylibre SAS
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
#  creator_id               :integer(4)
#  currency                 :string
#  expected_population      :decimal(19, 4)   not null
#  id                       :integer(4)       not null, primary key
#  inventory_id             :integer(4)       not null
#  lock_version             :integer(4)       default(0), not null
#  product_id               :integer(4)       not null
#  product_movement_id      :integer(4)
#  unit_pretax_stock_amount :decimal(19, 4)   default(0.0), not null
#  updated_at               :datetime         not null
#  updater_id               :integer(4)
#

require 'test_helper'

class InventoryItemTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions

  # Regression test for issue #2681: the inventories#show list column used
  # the bare chain `product.conditioning_unit.name` as its label_method.
  # Hard-deleted products leave inventory_items as orphans (no FK constraint
  # on product_id), so `product` is nil at render time and the page crashes.
  # The model now exposes a safe-navigated accessor used by the column.
  test 'product_conditioning_unit_name returns nil when product is missing' do
    item = InventoryItem.new
    assert_nil item.product
    assert_nil item.product_conditioning_unit_name
  end
end
