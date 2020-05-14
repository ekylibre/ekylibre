# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2020 Ekylibre SAS
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
# == Table: taxes
#
#  active                            :boolean          default(FALSE), not null
#  amount                            :decimal(19, 4)   default(0.0), not null
#  collect_account_id                :integer
#  country                           :string           not null
#  created_at                        :datetime         not null
#  creator_id                        :integer
#  deduction_account_id              :integer
#  description                       :text
#  fixed_asset_collect_account_id    :integer
#  fixed_asset_deduction_account_id  :integer
#  id                                :integer          not null, primary key
#  intracommunity                    :boolean          default(FALSE), not null
#  intracommunity_payable_account_id :integer
#  lock_version                      :integer          default(0), not null
#  name                              :string           not null
#  nature                            :string           not null
#  provider                          :jsonb
#  reference_name                    :string
#  updated_at                        :datetime         not null
#  updater_id                        :integer
#

require 'test_helper'

class TaxTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions
  test 'load defaults' do
    Tax.load_defaults
  end

  test 'load defaults with empty table' do
    Tax.delete_all
    Tax.load_defaults
  end

  test 'basic' do
    tax = Tax.create!(
      name: 'Standard',
      amount: 25,
      nature: :normal_vat,
      collect_account: Account.find_or_create_by_number('4566'),
      deduction_account: Account.find_or_create_by_number('4567'),
      country: :fr
    )
    assert_equal 250, tax.amount_of(200)
    assert_equal 250, tax.intracommunity_amount_of(200)
    assert_equal 400, tax.pretax_amount_of(500)
    assert_equal 1.25, tax.coefficient
  end

  test 'intracommunity' do
    tax = Tax.create!(
      name: 'Intra',
      amount: 30,
      nature: :normal_vat,
      intracommunity: true,
      collect_account: Account.find_or_create_by_number('4566'),
      deduction_account: Account.find_or_create_by_number('4567'),
      intracommunity_payable_account: Account.find_or_create_by_number('4452'),
      country: :fr
    )
    assert tax.intracommunity
    assert_equal 1, tax.coefficient
    assert_equal 0, tax.usable_amount
    assert_equal 30, tax.amount
    assert_equal 100, tax.amount_of(100), 'Intracommunity tax should not impact amount'
    assert_equal 130, tax.intracommunity_amount_of(100), 'Intracommunity tax should impact intracommunity amount'
  end

  test 'change amount' do
    tax = Tax.create!(
      name: 'Standard',
      amount: 25,
      nature: :normal_vat,
      collect_account: Account.find_or_create_by_number('4566'),
      deduction_account: Account.find_or_create_by_number('4567'),
      country: :fr
    )
    assert_equal 25, tax.amount
    tax.amount = 40
    assert tax.save
    assert_equal 40, tax.amount
  end

  test 'find_on' do
    assert_nil Tax.find_on(Date.civil(1702, 11, 13))
    tax = Tax.find_on(Date.civil(1979, 11, 13), country: :fr, nature: :normal_vat)
    assert tax, 'A tax should exist in France on 13/11/1979'
    assert_equal 17.6, tax.amount, 'Found tax should have 17.6 as amount'
  end
end
