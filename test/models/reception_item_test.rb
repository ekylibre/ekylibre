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
# == Table: parcel_items
#
#  activity_budget_id            :integer(4)
#  analysis_id                   :integer(4)
#  annotation                    :text
#  conditioning_quantity         :decimal(20, 10)
#  conditioning_unit_id          :integer(4)
#  created_at                    :datetime         not null
#  creator_id                    :integer(4)
#  currency                      :string
#  delivery_id                   :integer(4)
#  delivery_mode                 :string
#  equipment_id                  :integer(4)
#  id                            :integer(4)       not null, primary key
#  lock_version                  :integer(4)       default(0), not null
#  merge_stock                   :boolean          default(FALSE)
#  non_compliant                 :boolean
#  non_compliant_detail          :string
#  parcel_id                     :integer(4)       not null
#  parted                        :boolean          default(FALSE), not null
#  population                    :decimal(19, 4)
#  product_enjoyment_id          :integer(4)
#  product_id                    :integer(4)
#  product_identification_number :string
#  product_localization_id       :integer(4)
#  product_movement_id           :integer(4)
#  product_name                  :string
#  product_ownership_id          :integer(4)
#  product_work_number           :string
#  project_budget_id             :integer(4)
#  purchase_invoice_item_id      :integer(4)
#  purchase_order_item_id        :integer(4)
#  purchase_order_to_close_id    :integer(4)
#  role                          :string
#  sale_item_id                  :integer(4)
#  shape                         :geometry({:srid=>4326, :type=>"multi_polygon"})
#  source_product_id             :integer(4)
#  source_product_movement_id    :integer(4)
#  team_id                       :integer(4)
#  transporter_id                :integer(4)
#  type                          :string
#  unit_pretax_sale_amount       :decimal(19, 4)
#  unit_pretax_stock_amount      :decimal(19, 4)   default(0.0), not null
#  updated_at                    :datetime         not null
#  updater_id                    :integer(4)
#  variant_id                    :integer(4)
#
require 'test_helper'

class ReceptionItemTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  # Add tests here...
end
