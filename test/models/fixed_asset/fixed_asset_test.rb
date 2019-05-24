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

      fixed_asset = create :fixed_asset, :linear, :monthly,
                           amount: 150_000,
                           started_on: Date.new(2017, 1, 1),
                           percentage: 10.00

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

      fixed_asset.sold_on = sold_on
      assert fixed_asset.sell

      fixed_asset.reload

      fourth_f_d = fixed_asset.depreciations.where(position: 4).first

      assert_equal 833.33, fourth_f_d.amount
      assert_equal 833.33, fourth_f_d.journal_entry.real_credit
      assert_equal sold_on, fourth_f_d.journal_entry.printed_on
      assert_equal 150_000.00, fixed_asset.sold_journal_entry.real_credit
      assert_equal sold_on, fixed_asset.sold_journal_entry.printed_on
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

    private

      def depreciate_up_to(_depreciations, date)
        depreciations = FixedAssetDepreciation.with_active_asset.up_to(date)
        success = true

        depreciations.find_each { |dep| success &&= dep.update(accountable: true) }

        success
      end
  end
end