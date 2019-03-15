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
# == Table: fixed_assets
#
#  accounted_at                    :datetime
#  allocation_account_id           :integer          not null
#  asset_account_id                :integer
#  ceded                           :boolean
#  ceded_on                        :date
#  created_at                      :datetime         not null
#  creator_id                      :integer
#  currency                        :string           not null
#  current_amount                  :decimal(19, 4)
#  custom_fields                   :jsonb
#  depreciable_amount              :decimal(19, 4)   not null
#  depreciated_amount              :decimal(19, 4)   not null
#  depreciation_fiscal_coefficient :decimal(, )
#  depreciation_method             :string           not null
#  depreciation_percentage         :decimal(19, 4)
#  depreciation_period             :string
#  description                     :text
#  expenses_account_id             :integer
#  id                              :integer          not null, primary key
#  journal_entry_id                :integer
#  journal_id                      :integer          not null
#  lock_version                    :integer          default(0), not null
#  name                            :string           not null
#  number                          :string           not null
#  product_id                      :integer
#  purchase_amount                 :decimal(19, 4)
#  purchase_id                     :integer
#  purchase_item_id                :integer
#  purchased_on                    :date
#  sale_id                         :integer
#  sale_item_id                    :integer
#  scrapped_journal_entry_id       :integer
#  scrapped_on                     :date
#  sold_journal_entry_id           :integer
#  sold_on                         :date
#  started_on                      :date             not null
#  state                           :string
#  stopped_on                      :date             not null
#  updated_at                      :datetime         not null
#  updater_id                      :integer
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
      initial_shape: Charta.new_geometry('SRID=4326;MULTIPOLYGON(((-0.813218951225281 45.5985699786537,-0.813113003969193 45.5985455816635,-0.81300538033247 45.5987766488858,-0.813106298446655 45.5987876744046,-0.813218951225281 45.5985699786537)))')
    )

    @product = @variant.products.create!(
      initial_container: @storage,
      initial_population: 1,
      name: 'JD 5201'
    )

    currency = 'EUR'

    @journal = Journal.where(nature: 'various', currency: currency).first

    @asset_account = Account.find_or_create_by_number('998765')
    @allocation_account = Account.find_or_create_by_number('998764')
    @expenses_account = Account.find_or_create_by_number('998763')

    @started_on = Date.parse('2017-01-01')

    @up_to = Date.parse('2017-04-20')

    @sold_on = Date.parse('2017-04-20')
  end

  test 'simple fixed asset creation with tractor' do
    attributes = {
      name: @product.name,
      depreciable_amount: 150_000,
      depreciation_method: :linear,
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

  test 'depreciate class method returns the amount of depreciations according to until option provided' do
    FixedAssetDepreciation.delete_all
    FixedAsset.delete_all
    fixed_asset = create(:fixed_asset, depreciation_period: :yearly, depreciation_percentage: 100.0 / 3)
    fixed_asset.update(state: 'in_use')
    # create(:fixed_asset_depreciation, fixed_asset: fixed_asset)
    assert_equal 1, FixedAsset.count
    count = FixedAsset.depreciate(until: Date.civil(2018, 12, 31))
    assert_equal 2, count, 'Count of depreciations is invalid' + fixed_asset.depreciations.pluck(:started_on, :amount).to_yaml.yellow
  end

  test 'Fixed asset with regressive depreciation' do
    started_on = Date.parse('2018-06-15')
    attributes = {
      name: @product.name,
      depreciable_amount: 50_000,
      depreciation_method: :regressive,
      started_on: started_on,
      depreciation_period: :yearly,
      depreciation_percentage: 20.00,
      depreciation_fiscal_coefficient: 1.75,
      asset_account: @asset_account,
      allocation_account: @allocation_account,
      expenses_account: @expenses_account,
      product: @product,
      journal_id: @journal.id
    }

    fixed_asset = FixedAsset.create!(attributes)

    assert_equal 5, fixed_asset.depreciations.count

    depreciation_amount_assertion = [4375, 15968.75, 10379.69, 9638.28, 9638.28]

    currency = Preference[:currency]

    fixed_asset.depreciations.each_with_index do |depreciation, index|
      assert_equal currency.to_currency.round(depreciation_amount_assertion[index]), depreciation.amount.to_f
    end
  end

  test 'a fixed asset with regressive depreciation and all mandatory parameters should be valid' do
    started_on = Date.parse('2018-06-15')
    attributes = {
      name: @product.name,
      depreciable_amount: 50_000,
      depreciation_method: :regressive,
      started_on: started_on,
      depreciation_period: :yearly,
      depreciation_percentage: 20.00,
      depreciation_fiscal_coefficient: 1.75,
      asset_account: @asset_account,
      allocation_account: @allocation_account,
      expenses_account: @expenses_account,
      product: @product,
      journal_id: @journal.id
    }

    fixed_asset = FixedAsset.create!(attributes)
    valid = fixed_asset.valid?

    assert valid, fixed_asset.errors.messages
  end

  test 'stopped_on, allocation_account, expenses_account are not mandatory when a FixedAsset uses the :none depreciation method' do
    attributes = {
      name: @product.name,
      depreciable_amount: 50_000,
      depreciation_method: :none,
      started_on: Date.parse('2018-06-15'),
      asset_account: @asset_account,
      journal_id: @journal.id
    }

    fixed_asset = FixedAsset.new attributes
    valid = fixed_asset.valid?

    assert valid, fixed_asset.errors.messages.map {|_, v| v}.flatten
  end

  test 'a FixedAsset depreciated with :none method should not have any FixedAssetDepreciation' do
    attributes = {
      name: @product.name,
      depreciable_amount: 50_000,
      depreciation_method: :none,
      started_on: Date.parse('2018-06-15'),
      asset_account: @asset_account,
      journal_id: @journal.id
    }

    fixed_asset = FixedAsset.create! attributes

    assert_equal 0, fixed_asset.depreciations.count, "Should not have a depreciation"
  end

  test 'depreciations periods are computed correctly when the FinancialYear does not start the first day of the year' do
    FinancialYear.delete_all
    [2017, 2018].each do |year|
      start = Date.new year, 3, 1
      assert FinancialYear.create started_on: start, stopped_on: start + 1.year - 1.day
    end

    attributes = {
      name: @product.name,
      depreciable_amount: 50_000,
      depreciation_method: :linear,
      started_on: Date.new(2017, 3, 1),
      depreciation_period: :yearly,
      depreciation_percentage: 10.00,
      asset_account: @asset_account,
      allocation_account: @allocation_account,
      expenses_account: @expenses_account,
      product: @product,
      journal_id: @journal.id
    }

    assert fa = FixedAsset.create(attributes)
    fa.reload
    assert fa.depreciations.to_a.all? { |dep| dep.started_on.month == 3 }, "All depreciations periods should start on the same month as the begining of the FinancialYear"
  end

  test 'a draft FixedAsset depreciations are edited when relevant fields of it are edited' do
    FinancialYear.delete_all
    [2017, 2018].each do |year|
      start = Date.new year, 3, 1
      assert FinancialYear.create started_on: start, stopped_on: start + 1.year - 1.day
    end

    attributes = {
      name: @product.name,
      depreciable_amount: 50_000,
      depreciation_method: :linear,
      started_on: Date.new(2017, 3, 1),
      depreciation_period: :yearly,
      depreciation_percentage: 20.00,
      asset_account: @asset_account,
      allocation_account: @allocation_account,
      expenses_account: @expenses_account,
      product: @product,
      journal_id: @journal.id
    }

    fa = FixedAsset.create!(attributes)

    assert_equal 5, fa.depreciations.count
    assert_equal 50_000, fa.depreciations.map(&:amount).reduce(&:+)

    fa.depreciation_percentage = 10.00
    fa.depreciable_amount = 100_000
    assert fa.save

    assert_equal 10, fa.depreciations.count
    assert_equal 100_000, fa.depreciations.map(&:amount).reduce(&:+)
  end

  test 'A FixedAsset is valid when there is no FinancialYear at its started_on date' do
    FinancialYear.delete_all
    fa = FixedAsset.new(
      allocation_account: @allocation_account,
      depreciation_method: :linear,
      journal: @journal,
      depreciable_amount: 50_000,
      name: @product.name,
      started_on: '2018-05-01',
      stopped_on: '2028-04-30',
      asset_account: @asset_account,
      expenses_account: @expenses_account
    )
    assert fa.valid?
  end

  test 'A FixedAsset created before the first opened FinancialYear creates the correct depreciations entries' do
    FinancialYear.delete_all
    (2010...2015).each do |year|
      assert fy = FinancialYear.create(started_on: Date.new(year, 1, 1), stopped_on: Date.new(year, 12, 31), state: :locked)
    end
    [2016, 2017].each do |year|
      assert fy = FinancialYear.create(started_on: Date.new(year, 1, 1), stopped_on: Date.new(year, 12, 31))
    end

    fa = FixedAsset.new(
      name: @product.name,
      depreciable_amount: 50_000,
      depreciation_method: :linear,
      depreciation_percentage: 10,
      started_on: '2008-01-01',
      journal: @journal,
      asset_account: @asset_account,
      expenses_account: @expenses_account,
      allocation_account: @allocation_account
    )

    assert fa.save
    deps = fa.depreciations.to_a
    assert_equal 10, deps.length
    partitionned = deps.partition { |dep| dep.started_on.year < 2016 }

    assert_equal 8, partitionned[0].length
    assert partitionned[0].all? &:locked?

    assert_not partitionned[1].any? &:locked?
  end

  private

    def depreciate_up_to(_depreciations, date)
      depreciations = FixedAssetDepreciation.with_active_asset.up_to(date)
      success = true

      depreciations.find_each { |dep| success &&= dep.update(accountable: true) }

      success
    end
end
