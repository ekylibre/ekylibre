# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2019 Ekylibre SAS
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
# == Table: inventories
#
#  accounted_at      :datetime
#  achieved_at       :datetime
#  created_at        :datetime         not null
#  creator_id        :integer
#  currency          :string
#  custom_fields     :jsonb
#  financial_year_id :integer
#  id                :integer          not null, primary key
#  journal_entry_id  :integer
#  lock_version      :integer          default(0), not null
#  name              :string           not null
#  number            :string           not null
#  reflected         :boolean          default(FALSE), not null
#  reflected_at      :datetime
#  responsible_id    :integer
#  updated_at        :datetime         not null
#  updater_id        :integer
#

require 'test_helper'

class InventoryTest < ActiveSupport::TestCase
  test_model_actions

  setup do
    @product = Product.first
    @variant = @product.variant
  end

  test 'refresh' do
    FinancialYear.delete_all
    year = FinancialYear.create!(
      closed: false,
      code: 'inventory_test',
      currency: 'EUR',
      currency_precision: 2,
      started_on: Date.today.beginning_of_year,
      stopped_on: Date.today.end_of_year
    )
    inventory = Inventory.create!(name: Date.today.year.to_s, achieved_at: Date.today.end_of_year - 16.day, financial_year: year)
    inventory.refresh!
    inventory.reflect
  end

  test 'Test variant specified when bookkeep' do
    FinancialYear.delete_all

    year = FinancialYear.create!(
      closed: false,
      code: 'inventory_test',
      currency: 'EUR',
      currency_precision: 2,
      started_on: Date.today.beginning_of_year,
      stopped_on: Date.today.end_of_year
    )

    inventory = Inventory.create!(name: Date.today.year.to_s, achieved_at: Date.today.end_of_year - 16.day, financial_year: year)
    inventory.items.create!(product: @product, actual_population: 4, expected_population: 10, unit_pretax_stock_amount: 10)
    inventory.refresh!
    inventory.reflect

    journal_entry_items = inventory.journal_entry.items

    # jei_s variant must be defined
    assert_not journal_entry_items.map(&:variant_id).include? nil
  end
end
