# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2015 Brice Texier, David Joulin
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
# == Table: financial_assets
#
#  allocation_account_id   :integer          not null
#  ceded                   :boolean
#  ceded_on                :date
#  charges_account_id      :integer
#  created_at              :datetime         not null
#  creator_id              :integer
#  currency                :string(3)        not null
#  current_amount          :decimal(19, 4)
#  depreciable_amount      :decimal(19, 4)   not null
#  depreciated_amount      :decimal(19, 4)   not null
#  depreciation_method     :string(255)      not null
#  depreciation_percentage :decimal(19, 4)
#  description             :text
#  id                      :integer          not null, primary key
#  journal_id              :integer          not null
#  lock_version            :integer          default(0), not null
#  name                    :string(255)      not null
#  number                  :string(255)      not null
#  purchase_amount         :decimal(19, 4)
#  purchase_id             :integer
#  purchase_item_id        :integer
#  purchased_on            :date
#  sale_id                 :integer
#  sale_item_id            :integer
#  started_on              :date             not null
#  stopped_on              :date             not null
#  updated_at              :datetime         not null
#  updater_id              :integer
#
require 'test_helper'

class FinancialAssetTest < ActiveSupport::TestCase
  test_fixtures
end
