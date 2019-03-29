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
# == Table: purchases
#
#  accounted_at                             :datetime
#  affair_id                                :integer
#  amount                                   :decimal(19, 4)   default(0.0), not null
#  confirmed_at                             :datetime
#  contract_id                              :integer
#  created_at                               :datetime         not null
#  creator_id                               :integer
#  currency                                 :string           not null
#  custom_fields                            :jsonb
#  delivery_address_id                      :integer
#  description                              :text
#  id                                       :integer          not null, primary key
#  invoiced_at                              :datetime
#  journal_entry_id                         :integer
#  lock_version                             :integer          default(0), not null
#  nature_id                                :integer
#  number                                   :string           not null
#  payment_at                               :datetime
#  payment_delay                            :string
#  planned_at                               :datetime
#  pretax_amount                            :decimal(19, 4)   default(0.0), not null
#  quantity_gap_on_invoice_journal_entry_id :integer
#  reference_number                         :string
#  responsible_id                           :integer
#  state                                    :string           not null
#  supplier_id                              :integer          not null
#  tax_payability                           :string           not null
#  undelivered_invoice_journal_entry_id     :integer
#  updated_at                               :datetime         not null
#  updater_id                               :integer
#

require 'test_helper'

class PurchaseTest < ActiveSupport::TestCase
  test_model_actions

  setup do
    @variant = ProductNatureVariant.import_from_nomenclature(:carrot)
  end

  test 'rounds' do
    nature = PurchaseNature.first
    assert nature
    purchase = Purchase.create!(nature: nature, supplier: Entity.normal.first)
    assert purchase
    variants = ProductNatureVariant.where(nature: ProductNature.where(population_counting: :decimal))
    tax = Tax.create!(
      name: 'Reduced',
      amount: 5.5,
      nature: :normal_vat,
      collect_account: Account.find_or_create_by_number('4566'),
      deduction_account: Account.find_or_create_by_number('4567'),
      country: :fr
    )
    item = purchase.items.create!(variant: variants.first, quantity: 4, unit_pretax_amount: 3.791, tax: tax)
    assert item
    assert_equal 16, item.amount
    assert_equal 16, purchase.amount
  end

  test 'simple creation' do
    nature = PurchaseNature.first
    assert nature
    supplier = Entity.where(supplier: true).first
    assert supplier
    purchase = Purchase.create!(nature: nature, supplier: supplier)
    3.times do |index|
      variant = ProductNatureVariant.all.sample
      tax = Tax.find_by(amount: 20)
      quantity = index + 1
      item = purchase.items.build(variant: variant, unit_pretax_amount: 100, tax: tax, quantity: quantity)
      item.save!
      assert_equal(quantity * 100, item.pretax_amount, "Item pre-tax amount should be #{quantity * 100}. Got #{item.pretax_amount.inspect}")
      assert_equal(quantity * 120, item.amount, "Item amount should be #{quantity * 120}. Got #{item.amount.inspect}")
      assert purchase.amount > 0, "Purchase amount should be greater than 0. Got: #{purchase.amount}"
    end
    2.times do |index|
      variant = ProductNatureVariant.all.sample
      tax = Tax.create_with(
        collect_account: Account.find_or_create_by_number('4566'),
        deduction_account: Account.find_or_create_by_number('4567'),
        intracommunity_payable_account: Account.find_or_create_by_number('4452'),
        country: :fr
      ).find_or_create_by!(amount: 20, intracommunity: true, nature: :normal_vat)
      quantity = index + 1
      item = purchase.items.build(variant: variant, unit_pretax_amount: 100, tax: tax, quantity: quantity)
      item.save!
      assert_equal(quantity * 100, item.pretax_amount, "Item pre-tax amount should be #{quantity * 100}. Got #{item.pretax_amount.inspect}")
      assert_equal(quantity * 100, item.amount, "Item amount should be #{quantity * 100}. Got #{item.amount.inspect}")
      assert purchase.amount > 0, "Purchase amount should be greater than 0. Got: #{purchase.amount}"
    end

    assert_equal 5, purchase.items.count

    variant = ProductNatureVariant.all.sample

    item = purchase.items.build(variant: variant, unit_pretax_amount: 100, tax: Tax.find_by(amount: 20), quantity: 0.999, pretax_amount: 100)
    item.save!
    assert_equal 100, item.pretax_amount

    item = purchase.items.build(variant: variant, unit_pretax_amount: 100, tax: Tax.find_by(amount: 20), quantity: 0.999, pretax_amount: 99, amount: 120)
    item.save!
    assert_equal 120, item.amount

    assert_equal 7, purchase.items.count
  end

  test 'simple creation with nested items' do
    attributes = {
      nature: PurchaseNature.first,
      supplier: Entity.where(supplier: true).first,
      items_attributes: {
        '0' => {
          tax: Tax.find_by!(amount: 20),
          variant: ProductNatureVariant.first,
          unit_pretax_amount: 100,
          quantity: 1
        },
        '1' => {
          tax: Tax.find_by!(amount: 0),
          variant_id: ProductNatureVariant.first.id,
          unit_pretax_amount: 450,
          quantity: 2
        },
        '2' => { # Invalid item (rejected)
          tax: Tax.find_by!(amount: 19.6),
          unit_pretax_amount: 123,
          quantity: 17
        }
      }
    }.deep_stringify_keys
    purchase = Purchase.create!(attributes)
    assert_equal 2, purchase.items.count
    assert_equal 1000, purchase.pretax_amount
    assert_equal 1020, purchase.amount

    purchase.propose!
    purchase.confirm!
    purchase.invoice!
  end

  test 'cannot have an empty state - it is set to draft by default' do
    nature   = PurchaseNature.create!(currency: 'EUR', name: 'Perishables')
    max      = Entity.create!(first_name: 'Max', last_name: 'Rockatansky', nature: :contact)
    purchase = Purchase.create!(supplier: max, nature: nature, currency: 'USD', state: nil)

    assert_equal 'draft', purchase.state

    purchase.update(state: nil)

    assert_equal 'draft', purchase.state
  end

  test 'default_currency is nature\'s currency if currency is not specified' do
    Payslip.delete_all
    Purchase.delete_all
    PurchaseNature.delete_all
    OutgoingPayment.delete_all
    Entity.delete_all

    nature     = PurchaseNature.create!(currency: 'EUR', name: 'Perishables')
    max        = Entity.create!(first_name: 'Max', last_name: 'Rockatansky', nature: :contact)
    with       = Purchase.create!(supplier: max, nature: nature, currency: 'USD')
    without    = Purchase.create!(supplier: max, nature: nature)

    assert_equal 'USD', with.default_currency
    assert_equal 'EUR', without.default_currency
  end

  test 'affair_class points to correct class' do
    assert_equal PurchaseAffair, Purchase.affair_class
  end

  test 'payment date computation' do
    purchase = Purchase.create!(
      nature: PurchaseNature.first,
      planned_at: Date.civil(2015, 1, 1),
      supplier: Entity.where(supplier: true).first,
      items_attributes: {
        '0' => {
          tax: Tax.find_by!(amount: 20),
          variant: ProductNatureVariant.first,
          unit_pretax_amount: 100,
          quantity: 1
        },
        '1' => {
          tax: Tax.find_by!(amount: 0),
          variant_id: ProductNatureVariant.first.id,
          unit_pretax_amount: 450,
          quantity: 2
        }
      }
    )
    assert_equal Date.civil(2015, 1, 1), purchase.payment_at

    purchase.payment_delay = '1 year'
    purchase.save!
    assert_equal Date.civil(2016, 1, 1), purchase.payment_at

    purchase.payment_delay = '2 months'
    purchase.save!
    assert_equal Date.civil(2015, 3, 1), purchase.payment_at
  end

  test 'updating third updates third in affair if purchase is alone in the deals' do
    original_supplier = Entity.create(first_name: 'First', last_name: 'Supplier', supplier: true)
    replacement_supplier = Entity.create(first_name: 'Second', last_name: 'Supplier', supplier: true)

    purchase = Purchase.create!(
      nature: PurchaseNature.first,
      planned_at: Date.civil(2015, 1, 1),
      supplier: original_supplier,
      items_attributes: {
        '0' => {
          tax: Tax.find_by!(amount: 20),
          variant: ProductNatureVariant.first,
          unit_pretax_amount: 100,
          quantity: 1
        },
        '1' => {
          tax: Tax.find_by!(amount: 0),
          variant_id: ProductNatureVariant.first.id,
          unit_pretax_amount: 450,
          quantity: 2
        }
      }
    )
    assert_equal original_supplier, purchase.affair.third

    purchase.update(supplier: replacement_supplier)
    assert_equal replacement_supplier, purchase.affair.third

    purchase.affair.purchases.create!(
      nature: PurchaseNature.first,
      planned_at: Date.civil(2015, 1, 1),
      supplier: replacement_supplier,
      items_attributes: {
        '0' => {
          tax: Tax.find_by!(amount: 20),
          variant: ProductNatureVariant.first,
          unit_pretax_amount: 100,
          quantity: 1
        },
        '1' => {
          tax: Tax.find_by!(amount: 0),
          variant_id: ProductNatureVariant.first.id,
          unit_pretax_amount: 450,
          quantity: 2
        }
      }
    )

    assert_equal replacement_supplier, purchase.affair.third

    purchase.update(supplier: original_supplier)
    assert_equal replacement_supplier, purchase.affair.third
  end
end
