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
# == Table: sale_items
#
#  account_id             :integer
#  accounting_label       :string
#  activity_budget_id     :integer
#  amount                 :decimal(19, 4)   default(0.0), not null
#  annotation             :text
#  codes                  :jsonb
#  compute_from           :string           not null
#  created_at             :datetime         not null
#  creator_id             :integer
#  credited_item_id       :integer
#  credited_quantity      :decimal(19, 4)
#  currency               :string           not null
#  depreciable_product_id :integer
#  fixed                  :boolean          default(FALSE), not null
#  fixed_asset_id         :integer
#  id                     :integer          not null, primary key
#  label                  :text
#  lock_version           :integer          default(0), not null
#  position               :integer
#  preexisting_asset      :boolean
#  pretax_amount          :decimal(19, 4)   default(0.0), not null
#  quantity               :decimal(19, 4)   default(1.0), not null
#  reduction_percentage   :decimal(19, 4)   default(0.0), not null
#  sale_id                :integer          not null
#  tax_id                 :integer
#  team_id                :integer
#  unit_amount            :decimal(19, 4)   default(0.0), not null
#  unit_pretax_amount     :decimal(19, 4)
#  updated_at             :datetime         not null
#  updater_id             :integer
#  variant_id             :integer          not null
#

require 'test_helper'

class SaleItemTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions

  attr_reader :sale, :standard_vat, :reduced_vat, :variants

  setup do
    nature = SaleNature.find_or_create_by(currency: 'EUR')
    assert nature
    client = Entity.normal.first
    assert client
    @sale = Sale.create!(nature: nature, client: client, invoiced_at: DateTime.new(2018, 1, 1))
    assert @sale

    # Standard case
    @standard_vat = Tax.create!(
      name: 'Standard',
      amount: 20,
      nature: :normal_vat,
      collect_account: Account.find_or_create_by_number('45661'),
      deduction_account: Account.find_or_create_by_number('45671'),
      country: :fr
    )

    # Limit case
    @reduced_vat = Tax.create!(
      name: 'Reduced',
      amount: 5.5,
      nature: :normal_vat,
      collect_account: Account.find_or_create_by_number('45662'),
      deduction_account: Account.find_or_create_by_number('45672'),
      country: :fr
    )

    @variants = ProductNatureVariant.where(nature: ProductNature.where(population_counting: :decimal))
  end

  test 'should compute from unit pretax amount with given pretax amount' do
    item = sale.items.create!(variant: variants.first, compute_from: :unit_pretax_amount, quantity: 3, unit_pretax_amount: 100, pretax_amount: 10_000, tax: standard_vat)
    assert_equal 100, item.unit_pretax_amount
    assert_equal 300, item.pretax_amount
    assert_equal 360, item.amount
  end

  test 'should compute from unit pretax amount' do
    item = sale.items.create!(variant: variants.second, compute_from: :unit_pretax_amount, quantity: 3, unit_pretax_amount: 3.33, tax: standard_vat)
    assert_equal  3.33, item.unit_pretax_amount
    assert_equal  9.99, item.pretax_amount
    assert_equal 11.99, item.amount

    item = sale.items.create!(variant: variants.second, compute_from: :unit_pretax_amount, quantity: 4, unit_pretax_amount: 3.791, tax: reduced_vat)
    assert_equal 3.791, item.unit_pretax_amount
    assert_equal 15.16, item.pretax_amount
    assert_equal 16.00, item.amount
  end

  test 'should compute from pretax amount' do
    item = sale.items.create!(variant: variants.third, compute_from: :pretax_amount, quantity: 3, pretax_amount: 10, tax: standard_vat)
    assert_equal 3.33, item.unit_pretax_amount
    assert_equal 10.0, item.pretax_amount
    assert_equal 12.0, item.amount
  end

  test 'should compute from pretax amount with too many decimals' do
    item = sale.items.create!(variant: variants.third, compute_from: :pretax_amount, quantity: 4, pretax_amount: 15.165, tax: reduced_vat)
    assert_equal 3.79, item.unit_pretax_amount
    assert_equal 15.165, item.pretax_amount
    assert_equal 16.00, item.amount
  end

  test 'should compute from amount' do
    item = sale.items.create!(variant: variants.fourth, compute_from: :amount, quantity: 4, amount: 16, tax: reduced_vat)
    assert_equal 3.79, item.unit_pretax_amount
    assert_equal 15.17, item.pretax_amount
    assert_equal 16.00, item.amount
  end

  test 'should compute from negative amount' do
    item = sale.items.create!(variant: variants.fourth, compute_from: :amount, quantity: 4, amount: -16, tax: reduced_vat)
    assert_equal -3.79, item.unit_pretax_amount
    assert_equal -15.17, item.pretax_amount
    assert_equal -16.00, item.amount
  end

  test 'should not compute anything existing field with reference number' do
    sale.update(reference_number: '125457877')
    item = sale.items.create!(
      variant: variants.fourth,
      compute_from: :amount,
      quantity: 4,
      unit_pretax_amount: 4,
      pretax_amount: 15,
      amount: 16,
      tax: standard_vat
    )
    assert_equal 4, item.unit_pretax_amount
    assert_equal 15, item.pretax_amount
    assert_equal 16, item.amount
  end

  test 'fixed_asset_id and depreciable_product_id are the only fields that can be updated if the sale status is invoice' do
    sale_item = create :sale_item, sale: sale
    fixed_asset = create :fixed_asset, :in_use, started_on: Date.new(2018, 1, 1)
    product = create :asset_fixable_product

    sale.invoice

    assert sale_item.sale.invoice?
    assert sale_item.update!(fixed_asset: fixed_asset)
    assert sale_item.update!(depreciable_product: product)
    assert_raises Ekylibre::Record::RecordNotUpdateable do
      sale_item.update!(amount: 100)
    end
  end
end
