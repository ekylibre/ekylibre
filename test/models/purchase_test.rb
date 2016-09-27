# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2016 Brice Texier, David Joulin
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
#  accounted_at                     :datetime
#  affair_id                        :integer
#  amount                           :decimal(19, 4)   default(0.0), not null
#  confirmed_at                     :datetime
#  created_at                       :datetime         not null
#  creator_id                       :integer
#  currency                         :string           not null
#  custom_fields                    :jsonb
#  delivery_address_id              :integer
#  description                      :text
#  id                               :integer          not null, primary key
#  invoiced_at                      :datetime
#  journal_entry_id                 :integer
#  lock_version                     :integer          default(0), not null
#  nature_id                        :integer
#  number                           :string           not null
#  planned_at                       :datetime
#  pretax_amount                    :decimal(19, 4)   default(0.0), not null
#  quantity_gap_on_invoice_entry_id :integer
#  reference_number                 :string
#  responsible_id                   :integer
#  state                            :string
#  supplier_id                      :integer          not null
#  undelivered_invoice_entry_id     :integer
#  updated_at                       :datetime         not null
#  updater_id                       :integer
#

require 'test_helper'

class PurchaseTest < ActiveSupport::TestCase
  test_model_actions
  test 'simple creation' do
    nature = PurchaseNature.first
    assert nature
    supplier = Entity.where(supplier: true).first
    assert supplier
    purchase = Purchase.create!(nature: nature, supplier: supplier)
    5.times do |index|
      variant = ProductNatureVariant.all.sample
      tax = Tax.find_by(amount: 20)
      quantity = index + 1
      item = purchase.items.build(variant: variant, unit_pretax_amount: 100, tax: tax, quantity: quantity)
      item.save!
      assert_equal(quantity * 100, item.pretax_amount, "Item pre-tax amount should be #{quantity * 100}. Got #{item.pretax_amount.inspect}")
      assert_equal(quantity * 120, item.amount, "Item amount should be #{quantity * 120}. Got #{item.amount.inspect}")
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
  end
end
