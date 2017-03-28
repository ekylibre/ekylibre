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
# == Table: debt_transfers
#
#  accounted_at                             :datetime
#  amount                                   :decimal(, )
#  created_at                               :datetime         not null
#  creator_id                               :integer
#  currency                                 :string           not null
#  id                                       :integer          not null, primary key
#  lock_version                             :integer          default(0), not null
#  purchase_affair_id                       :integer          not null
#  purchase_regularization_journal_entry_id :integer
#  sale_affair_id                           :integer          not null
#  sale_regularization_journal_entry_id     :integer
#  updated_at                               :datetime         not null
#  updater_id                               :integer
#
require 'test_helper'

class DebtTransferTest < ActiveSupport::TestCase
  test 'debt transfer from purchase affair to sale affair' do
    purchase_amount = 500

    account = Account.find_or_create_by_number('467')

    ### sale
    sale_nature = SaleNature.first
    sale = Sale.create!(nature: sale_nature, client: Entity.normal.first)
    variants = ProductNatureVariant.where(nature: ProductNature.where(population_counting: :decimal))
    tax = Tax.create!(
      name: 'Standard',
      amount: 20,
      nature: :normal_vat,
      collect_account: Account.find_or_create_by_number('4566'),
      deduction_account: Account.find_or_create_by_number('4567'),
      country: :fr
    )
    sale.items.create!(variant: variants.first, quantity: 2, pretax_amount: 1000, tax: tax, compute_from: 'pretax_amount')
    sale.invoice

    ### purchase
    purchase_nature = PurchaseNature.first
    purchase = Purchase.create!(nature: purchase_nature, supplier: Entity.normal.first)
    purchase.items.create!(variant: variants.first, quantity: 1, unit_pretax_amount: purchase_amount, tax: tax)
    purchase.invoice

    ### Try to balance Affair of 'sale' with sum of affair of 'purchase'

    # just to avoid false negative
    assert purchase.items.first.amount, purchase_amount

    dt = DebtTransfer.create!(sale_affair: sale.affair, purchase_affair: purchase.affair, amount: -purchase_amount)

    assert_equal -purchase_amount.to_f, dt.amount.to_f
    assert_equal sale.affair, dt.sale_affair
    assert_equal purchase.affair, dt.purchase_affair
    assert_not_nil dt.purchase_regularization_journal_entry
    assert_equal purchase_amount.to_f, dt.purchase_regularization_journal_entry.debit.to_f
    assert_equal 'purchase_regularization', dt.purchase_regularization_journal_entry.resource_prism

    # debit on supplier account of purchase third
    # assert_equal purchase.third.supplier_account.journal_entries.last
    # credit on account with usage 467 - sundry_debtors_and_creditors
    assert_equal purchase_amount, account.journal_entry_items.last.credit
  end
end
