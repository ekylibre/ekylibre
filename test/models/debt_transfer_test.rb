# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2018 Brice Texier, David Joulin
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
# == Table: debt_transfers
#
#  accounted_at            :datetime
#  affair_id               :integer          not null
#  amount                  :decimal(19, 4)   default(0.0)
#  created_at              :datetime         not null
#  creator_id              :integer
#  currency                :string           not null
#  debt_transfer_affair_id :integer          not null
#  id                      :integer          not null, primary key
#  journal_entry_id        :integer
#  lock_version            :integer          default(0), not null
#  nature                  :string           not null
#  number                  :string
#  updated_at              :datetime         not null
#  updater_id              :integer
#
require 'test_helper'

class DebtTransferTest < ActiveSupport::TestCase
  test 'debt transfer from purchase affair to sale affair' do
    sale_amount = 1000
    purchase_amount = 500

    ### sale
    sale_nature = SaleNature.first
    sale = Sale.create!(nature: sale_nature, client: Entity.normal.first)
    variants = ProductNatureVariant.where(nature: ProductNature.where(population_counting: :decimal))

    options = {
      name: '0% VAT',
      amount: 0,
      nature: :null_vat,
      collect_account: Account.find_or_create_by_number('4566'),
      deduction_account: Account.find_or_create_by_number('4567'),
      country: :fr
    }

    tax = Tax.create_with(options).find_or_create_by!(name: '0% VAT')

    sale.items.create!(variant: variants.first, quantity: 2, pretax_amount: sale_amount, tax: tax, compute_from: 'pretax_amount')
    sale.invoice

    ### purchase
    purchase_nature = PurchaseNature.first
    purchase = PurchaseInvoice.create!(nature: purchase_nature, supplier: Entity.normal.first)
    purchase.items.create!(variant: variants.first, quantity: 1, unit_pretax_amount: purchase_amount, tax: tax)

    # just to avoid false negative
    assert_equal purchase.items.first.amount, purchase_amount, "can't run debt transfer test without a valid purchase"

    count = DebtTransfer.count

    dt = DebtTransfer.create_and_reflect!(affair: sale.affair, debt_transfer_affair: purchase.affair)

    assert_equal count + 2, DebtTransfer.count, 'Two debt transfers should be created. Got: ' + (DebtTransfer.count - count).to_s

    assert_equal 'sale_regularization', dt.nature.to_s
    assert_equal purchase_amount.to_f, dt.amount.to_f
    assert_equal sale.affair, dt.affair
    assert_equal purchase.affair, dt.debt_transfer_affair
    assert_not_nil dt.journal_entry
    assert_equal purchase_amount.to_f, dt.journal_entry.debit.to_f

    assert_equal 0.0, dt.debt_transfer_affair.balance.to_f
    assert_equal -(sale_amount - purchase_amount).to_f, dt.affair.balance.to_f

    dt.destroy!

    assert_equal count, DebtTransfer.count, 'Two debt transfers should be destroyed. Got: ' + (DebtTransfer.count - count).to_s
  end
end
