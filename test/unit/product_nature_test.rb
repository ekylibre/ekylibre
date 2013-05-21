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
#  active                 :boolean          not null
#  alive                  :boolean          not null
#  asset_account_id       :integer          
#  category_id            :integer          not null
#  charge_account_id      :integer          
#  commercial_description :text             
#  commercial_name        :string(255)      not null
#  created_at             :datetime         not null
#  creator_id             :integer          
#  deliverable            :boolean          not null
#  depreciable            :boolean          not null
#  description            :text             
#  id                     :integer          not null, primary key
#  indivisible            :boolean          not null
#  lock_version           :integer          default(0), not null
#  name                   :string(255)      not null
#  number                 :string(32)       not null
#  producible             :boolean          not null
#  product_account_id     :integer          
#  purchasable            :boolean          not null
#  reductible             :boolean          not null
#  saleable               :boolean          not null
#  stock_account_id       :integer          
#  storable               :boolean          not null
#  storage                :boolean          not null
#  subscribing            :boolean          not null
#  subscription_duration  :string(255)      
#  subscription_nature_id :integer          
#  towable                :boolean          not null
#  traceable              :boolean          not null
#  tractive               :boolean          not null
#  transferable           :boolean          not null
#  unit_id                :integer          not null
#  updated_at             :datetime         not null
#  updater_id             :integer          
#  variety_id             :integer          not null
#
require 'test_helper'

class ProductNatureTest < ActiveSupport::TestCase

end
