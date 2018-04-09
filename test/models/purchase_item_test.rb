# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2018 Brice Texier, David Joulin
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
# == Table: purchase_items
#
#  account_id             :integer          not null
#  activity_budget_id     :integer
#  amount                 :decimal(19, 4)   default(0.0), not null
#  annotation             :text
#  conditionning          :integer
#  conditionning_quantity :integer
#  created_at             :datetime         not null
#  creator_id             :integer
#  currency               :string           not null
#  depreciable_product_id :integer
#  equipment_id           :integer
#  fixed                  :boolean          default(FALSE), not null
#  fixed_asset_id         :integer
#  fixed_asset_stopped_on :date
#  id                     :integer          not null, primary key
#  label                  :text
#  lock_version           :integer          default(0), not null
#  position               :integer
#  preexisting_asset      :boolean
#  pretax_amount          :decimal(19, 4)   default(0.0), not null
#  project_budget_id      :integer
#  purchase_id            :integer          not null
#  quantity               :decimal(19, 4)   not null
#  reduction_percentage   :decimal(19, 4)   default(0.0), not null
#  role                   :string
#  tax_id                 :integer          not null
#  team_id                :integer
#  unit_amount            :decimal(19, 4)   default(0.0), not null
#  unit_pretax_amount     :decimal(19, 4)   not null
#  updated_at             :datetime         not null
#  updater_id             :integer
#  variant_id             :integer
#

require 'test_helper'

class PurchaseItemTest < ActiveSupport::TestCase
  test_model_actions
  # Add tests here...
end
