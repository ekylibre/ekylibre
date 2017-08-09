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
# == Table: parcel_items
#
#  analysis_id                   :integer
#  created_at                    :datetime         not null
#  creator_id                    :integer
#  currency                      :string
#  id                            :integer          not null, primary key
#  lock_version                  :integer          default(0), not null
#  parcel_id                     :integer          not null
#  parted                        :boolean          default(FALSE), not null
#  population                    :decimal(19, 4)
#  pretax_amount                 :decimal(19, 4)   default(0.0), not null
#  product_enjoyment_id          :integer
#  product_id                    :integer
#  product_identification_number :string
#  product_localization_id       :integer
#  product_movement_id           :integer
#  product_name                  :string
#  product_ownership_id          :integer
#  purchase_item_id              :integer
#  sale_item_id                  :integer
#  shape                         :geometry({:srid=>4326, :type=>"multi_polygon"})
#  source_product_id             :integer
#  source_product_movement_id    :integer
#  unit_pretax_amount            :decimal(19, 4)   default(0.0), not null
#  unit_pretax_stock_amount      :decimal(19, 4)   default(0.0), not null
#  updated_at                    :datetime         not null
#  updater_id                    :integer
#  variant_id                    :integer
#
require 'test_helper'

class ParcelItemTest < ActiveSupport::TestCase
  test_model_actions
  test 'method for calculate average cost amount' do
    p = parcel_items(:parcel_items_001)
    refute_nil p.send(:average_cost_amount)
    assert p.send(:average_cost_amount)
  end

  test 'create variant valuing' do
    p = parcel_items(:parcel_items_001)
    quantity_new = 200
    quantity_action = 100
    variant_id = 1
    unitary_price = 15
    refute_nil p.send(:create_variant_valuing, quantity_new, quantity_action, variant_id, unitary_price)
    assert p.send(:create_variant_valuing, quantity_new, quantity_action, variant_id, unitary_price)
  end
  # Add tests here...
end
