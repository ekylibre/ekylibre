# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier, Thibaud Merigon
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
# == Table: product_natures
#
#  active                    :boolean          not null
#  asset_account_id          :integer
#  category_id               :integer          not null
#  charge_account_id         :integer
#  commercial_description    :text
#  commercial_name           :string(255)      not null
#  contour                   :string(255)
#  created_at                :datetime         not null
#  creator_id                :integer
#  depreciable               :boolean          not null
#  derivative_of             :string(127)
#  description               :text
#  id                        :integer          not null, primary key
#  individual                :boolean          not null
#  individual_unit_name      :string(255)
#  lock_version              :integer          default(0), not null
#  name                      :string(255)      not null
#  net_volume                :decimal(19, 4)
#  net_weight                :decimal(19, 4)
#  number                    :string(31)       not null
#  product_account_id        :integer
#  purchasable               :boolean          not null
#  purchase_unit             :string(255)
#  purchase_unit_coefficient :decimal(19, 4)
#  purchase_unit_modulo      :decimal(19, 4)
#  purchase_unit_name        :string(255)
#  reductible                :boolean          not null
#  sale_unit                 :string(255)
#  sale_unit_coefficient     :decimal(19, 4)
#  sale_unit_modulo          :decimal(19, 4)
#  sale_unit_name            :string(255)
#  saleable                  :boolean          not null
#  stock_account_id          :integer
#  storable                  :boolean          not null
#  subscribing               :boolean          not null
#  subscription_duration     :string(255)
#  subscription_nature_id    :integer
#  unit                      :string(255)      not null
#  updated_at                :datetime         not null
#  updater_id                :integer
#  variety                   :string(127)      not null
#
require 'test_helper'

class ProductNatureTest < ActiveSupport::TestCase

end
