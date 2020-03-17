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

module FixedAssetTest
  class FixedAssetTest < Ekylibre::Testing::ApplicationTestCase

    setup do
      [2017, 2018].each { |year| create :financial_year, year: year }
    end

    test 'simple fixed asset creation with tractor' do
      sold_on = Date.new 2017, 4, 20
      up_to = Date.new 2017, 4, 20
      product = create :asset_fixable_product, born_at: DateTime.new(2017, 1, 1)

      fixed_asset = create :fixed_asset, :linear, :monthly,
                           amount: 150_000,
                           started_on: Date.new(2017, 1, 1),
                           percentage: 10.00,
                           product: product

      assert_equal 120, fixed_asset.depreciations.count
      assert_equal 1250, fixed_asset.depreciations.first.amount

      # test when in_use fixed asset

      assert fixed_asset.start_up

      assert_equal 150_000.00, fixed_asset.journal_entry.real_credit
      assert_equal 150_000.00, fixed_asset.journal_entry.real_debit

      r = depreciate_up_to(fixed_asset.depreciations, up_to)

      fixed_asset.reload

      assert r

      f_d = fixed_asset.depreciations.first

      assert_equal 1250, f_d.journal_entry.real_credit
      assert_equal Date.parse('2017-01-31'), f_d.journal_entry.printed_on

      # test when sold fixed asset

      sale_item = create :sale_item, :fixed, variant: product.variant, fixed_asset: fixed_asset, amount: 150_000

      fixed_asset.reload

      fixed_asset.sold_on = sold_on
      assert fixed_asset.sell

      fixed_asset.reload

      fourth_f_d = fixed_asset.depreciations.where(position: 4).first

      assert_equal 818.97, fourth_f_d.amount
      assert_equal 818.97, fourth_f_d.journal_entry.real_credit
      assert_equal sold_on, fourth_f_d.journal_entry.printed_on
      assert_equal 150_000.00, fixed_asset.sold_journal_entry.real_credit
      assert_equal sold_on, fixed_asset.sold_journal_entry.printed_on
    end

    test 'protection' do
      fa = create :fixed_asset, :yearly,
                  started_on: Date.new(2017, 2, 1),
                  amount: 50_000,
                  percentage: 20.00

      assert fa.destroyable?
      assert fa.start_up
      assert_not fa.destroyable?

      FixedAssetDepreciator.new.depreciate([fa], up_to: Date.new(2017, 12, 31))
      fa.reload

      assert fa.depreciations.all?(&:destroyable?)

      fdep = fa.depreciations.first
      fdep.journal_entry.confirm
      fa.reload
      assert_not fa.depreciations.first.destroyable?
    end

    test 'depreciate class method returns the amount of depreciations according to until option provided' do
      fixed_asset = create :fixed_asset, :yearly, :in_use, percentage: 100.0 / 3, started_on: Date.new(2017, 1, 1)
      count = FixedAsset.depreciate(until: Date.civil(2018, 12, 31))
      assert_equal 2, count, 'Count of depreciations is invalid' + fixed_asset.depreciations.pluck(:started_on, :amount).to_yaml.yellow
    end

    test 'Fixed asset with regressive depreciation' do
      started_on = Date.new 2018, 10, 15

      fixed_asset = create :fixed_asset, :yearly, :regressive,
                           coefficient: 1.75,
                           started_on: started_on,
                           amount: 50_000,
                           percentage: 20.00

      assert_equal 5, fixed_asset.depreciations.count


      depreciation_amount_assertion = [4375, 15968.75, 10379.69, 9638.28, 9638.28]

      currency = Preference[:currency]

      fixed_asset.depreciations.each_with_index do |depreciation, index|
        assert_equal currency.to_currency.round(depreciation_amount_assertion[index]), depreciation.amount.to_f
      end
    end

    test 'a fixed asset with regressive depreciation and all mandatory parameters should be valid' do
      fixed_asset = build :fixed_asset, :yearly, :regressive,
                          coefficient: 1.75,
                          percentage: 20.00,
                          amount: 50_000,
                          started_on: Date.new(2018, 6, 15)

      res = fixed_asset.save

      assert res, fixed_asset.errors.messages.values.join(', ')
    end

    test 'a draft FixedAsset depreciations are edited when relevant fields of it are edited' do
      fa = create :fixed_asset, :yearly,
                  percentage: 20.0,
                  started_on: Date.new(2017, 1, 1),
                  amount: 50_000

      assert_equal 5, fa.depreciations.count
      assert_equal 50_000, fa.depreciations.map(&:amount).reduce(&:+)

      fa.depreciation_percentage = 10.00
      fa.depreciable_amount = 100_000
      assert fa.save

      assert_equal 10, fa.depreciations.count
      assert_equal 100_000, fa.depreciations.map(&:amount).reduce(&:+)
    end

    test 'linking a fixed asset to a sale updates tax, amounts and sold_on fields according to the sale it refers to' do
      variant = ProductNatureVariant.import_from_nomenclature(:tractor)
      fixed_asset = create :fixed_asset, :in_use, started_on: Date.new(2018, 1, 1)
      sale = create :sale, invoiced_at: DateTime.new(2018, 6, 1)
      sale_item = create :sale_item, :fixed, variant: variant, fixed_asset: fixed_asset, sale: sale
      fixed_asset.reload

      assert_equal fixed_asset.sale_id, sale.id
      assert_equal fixed_asset.sale_item_id, sale_item.id
      assert_equal fixed_asset.tax_id, sale_item.tax_id
      assert_equal fixed_asset.selling_amount, sale_item.amount
      assert_equal fixed_asset.pretax_selling_amount, sale_item.pretax_amount
      assert_equal fixed_asset.sold_on, sale.invoiced_at.to_date
    end

    test 'starting up a fixed asset sets the product born_at date accordingly' do
      product = create :asset_fixable_product, born_at: DateTime.new(2018, 6, 1)
      fixed_asset = create :fixed_asset, started_on: Date.new(2017, 3, 1), product: product

      assert_equal product.born_at, DateTime.new(2018, 6, 1)

      fixed_asset.start_up
      product.reload

      # Checks that product born_at should be set upon start_up action
      assert_equal product.born_at, fixed_asset.started_on.to_datetime
    end

    test 'adding a product to a fixed asset sets the product born_at accordingly' do
      create :journal, nature: :stocks
      product = create :asset_fixable_product, born_at: DateTime.new(2017, 1, 1)
      fixed_asset = create :fixed_asset, :in_use, started_on: Date.new(2017, 3, 1)
      intervention = create :intervention, started_at: DateTime.new(2017, 1, 15), stopped_at: DateTime.new(2017, 1, 15) + 1.hour
      tool = create :intervention_tool, intervention: intervention, product: product

      fixed_asset.update!(product: product)
      product.reload

      # Checks that product born_at shouldn't be set to a date posterior to the date of the intervention it was used for
      assert_equal product.born_at, DateTime.new(2017, 1, 1)

      intervention.update!(started_at: DateTime.new(2017, 6, 1), stopped_at: DateTime.new(2017, 6, 1) + 1.hour)
      fixed_asset.save!
      product.reload

      assert_equal product.born_at, fixed_asset.started_on.to_datetime
    end

    private

      def depreciate_up_to(_depreciations, date)
        depreciations = FixedAssetDepreciation.with_active_asset.up_to(date)
        success = true

        depreciations.find_each { |dep| success &&= dep.update(accountable: true) }

        success
      end
  end
end
