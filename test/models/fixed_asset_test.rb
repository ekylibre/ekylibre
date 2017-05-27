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
# == Table: fixed_assets
#
#  accounted_at              :datetime
#  allocation_account_id     :integer          not null
#  asset_account_id          :integer
#  ceded                     :boolean
#  ceded_on                  :date
#  created_at                :datetime         not null
#  creator_id                :integer
#  currency                  :string           not null
#  current_amount            :decimal(19, 4)
#  custom_fields             :jsonb
#  depreciable_amount        :decimal(19, 4)   not null
#  depreciated_amount        :decimal(19, 4)   not null
#  depreciation_method       :string           not null
#  depreciation_percentage   :decimal(19, 4)
#  depreciation_period       :string
#  description               :text
#  expenses_account_id       :integer
#  id                        :integer          not null, primary key
#  journal_entry_id          :integer
#  journal_id                :integer          not null
#  lock_version              :integer          default(0), not null
#  name                      :string           not null
#  number                    :string           not null
#  product_id                :integer
#  purchase_amount           :decimal(19, 4)
#  purchase_id               :integer
#  purchase_item_id          :integer
#  purchased_on              :date
#  sale_id                   :integer
#  sale_item_id              :integer
#  scrapped_journal_entry_id :integer
#  scrapped_on               :date
#  sold_journal_entry_id     :integer
#  sold_on                   :date
#  started_on                :date             not null
#  state                     :string
#  stopped_on                :date             not null
#  updated_at                :datetime         not null
#  updater_id                :integer
#
require 'test_helper'

class FixedAssetTest < ActiveSupport::TestCase
  test_model_actions

  setup do
    @variant = ProductNatureVariant.import_from_nomenclature(:tractor)
    @entity = Entity.create!(last_name: 'JOHN DEERE SA')
    @address = @entity.addresses.create!(canal: 'mail', mail_line_1: 'Yolo', mail_line_2: 'Another test')

    @building_division_variant = ProductNatureVariant.import_from_nomenclature(:building_division)
    @storage = BuildingDivision.create!(
      variant: @building_division_variant,
      name: 'Tractor Stockage',
      initial_shape: Charta::MultiPolygon.new('SRID=4326;MULTIPOLYGON(((-0.813218951225281 45.5985699786537,-0.813113003969193 45.5985455816635,-0.81300538033247 45.5987766488858,-0.813106298446655 45.5987876744046,-0.813218951225281 45.5985699786537)))')
    )

    @product = @variant.products.create!(
      initial_container: @storage,
      initial_population: 1,
      name: 'JD 5201'
    )

    currency = 'EUR'

    @journal = Journal.where(nature: 'various', currency: currency).first

    @asset_account = Account.find_or_create_by_number('2154')
    @allocation_account = Account.find_or_create_by_number('2815')
    @expenses_account = Account.find_or_create_by_number('6811')

    @started_on = Date.parse('2017-01-01')

    @up_to = Date.parse('2017-04-20')

    @sold_on = Date.parse('2017-04-20')
  end

  test 'simple fixed asset creation with tractor' do
    attributes = {
      name: @product.name,
      depreciable_amount: 150_000,
      depreciation_method: :simplified_linear,
      started_on: @started_on,
      depreciation_period: :monthly,
      depreciation_percentage: 10.00,
      asset_account: @asset_account,
      allocation_account: @allocation_account,
      expenses_account: @expenses_account,
      product: @product,
      journal_id: @journal.id
    }

    fixed_asset = FixedAsset.create!(attributes)

    assert_equal 120, fixed_asset.depreciations.count
    assert_equal 1250, fixed_asset.depreciations.first.amount

    # test when in_use fixed asset

    fixed_asset.state = :in_use
    fixed_asset.save!

    assert_equal 150_000.00, fixed_asset.journal_entry.real_credit
    assert_equal 150_000.00, fixed_asset.journal_entry.real_debit

    r = depreciate_up_to(fixed_asset.depreciations, @up_to)

    fixed_asset.reload

    assert r

    f_d = fixed_asset.depreciations.first

    assert_equal 1250, f_d.journal_entry.real_credit
    assert_equal Date.parse('2017-01-31'), f_d.journal_entry.printed_on

    # test when sold fixed asset

    fixed_asset.sold_on = @sold_on
    fixed_asset.state = :sold
    fixed_asset.save!

    fixed_asset.reload

    fourth_f_d = fixed_asset.depreciations.where(position: 4).first

    assert_equal 833.33, fourth_f_d.amount
    assert_equal 833.33, fourth_f_d.journal_entry.real_credit
    assert_equal Date.parse('2017-04-30'), fourth_f_d.journal_entry.printed_on
    assert_equal 150_000.00, fixed_asset.sold_journal_entry.real_credit
    assert_equal @sold_on, fixed_asset.sold_journal_entry.printed_on
  end

  private

  def depreciate_up_to(depreciations, date)
    depreciations = FixedAssetDepreciation.with_active_asset.up_to(date)
    success = true

    depreciations.find_each { |dep| success &&= dep.update(accountable: true) }

    success
  end
end
