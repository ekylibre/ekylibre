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
# == Table: affairs
#
#  accounted_at           :datetime
#  cash_session_id        :integer
#  closed                 :boolean          default(FALSE), not null
#  closed_at              :datetime
#  created_at             :datetime         not null
#  creator_id             :integer
#  credit                 :decimal(19, 4)   default(0.0), not null
#  currency               :string           not null
#  dead_line_at           :datetime
#  deals_count            :integer          default(0), not null
#  debit                  :decimal(19, 4)   default(0.0), not null
#  description            :text
#  id                     :integer          not null, primary key
#  journal_entry_id       :integer
#  letter                 :string
#  lock_version           :integer          default(0), not null
#  name                   :string
#  number                 :string
#  origin                 :string
#  pretax_amount          :decimal(19, 4)   default(0.0)
#  probability_percentage :decimal(19, 4)   default(0.0)
#  responsible_id         :integer
#  state                  :string
#  third_id               :integer          not null
#  type                   :string
#  updated_at             :datetime         not null
#  updater_id             :integer
#
require 'test_helper'

class PurchaseAffairTest < ActiveSupport::TestCase
  include Test::Affairable

  test 'homogeneousity' do
    purchase = create(:purchase_invoice)
    # byebug
    assert_equal PurchaseAffair, purchase.affair.class
    assert_raise Exception do
      purchase.affair.deal_with! Sale.first
    end
  end

  test 'balancing with payment' do
    purchase = new_valid_purchases_invoice

    payment = PurchasePayment.create!(
      payee: purchase.supplier,
      amount: purchase.amount,
      to_bank_at: Time.zone.now,
      responsible: User.first,
      delivered: true,
      mode: OutgoingPaymentMode.where(
        with_accounting: true,
        cash: Cash.where(currency: purchase.currency)
      ).first
    )

    purchase.deal_with! payment.affair

    assert_equal purchase.affair, payment.affair

    check_closed_state(purchase.affair)
  end

  test 'finishing with profit gap' do
    purchase = new_valid_purchases_invoice
    assert_equal 1, purchase.affair.deals.count
    assert purchase.affair.finishable?
    assert_equal 1, purchase.affair.deals.count
    purchase.affair.finish
    assert_equal 2, purchase.affair.deals.count

    check_closed_state(purchase.affair)
  end

  test 'balancing with payment and a loss gap' do
    purchase = new_valid_purchases_invoice

    payment = PurchasePayment.create!(
      payee: purchase.supplier,
      amount: purchase.amount + 5,
      to_bank_at: Time.zone.now,
      responsible: User.first,
      delivered: true,
      mode: OutgoingPaymentMode.where(
        with_accounting: true,
        cash: Cash.where(currency: purchase.currency)
      ).first
    )

    purchase.deal_with! payment.affair

    assert_equal purchase.affair, payment.affair

    assert_equal 2, purchase.affair.deals.count
    assert purchase.affair.finishable?
    assert_equal 2, purchase.affair.deals.count
    purchase.affair.finish
    assert_equal 3, purchase.affair.deals.count

    check_closed_state(purchase.affair)
  end

  test 'finishing with regularization' do
    purchase = new_valid_purchases_invoice
    assert_equal 1, purchase.affair.deals.count

    journal_entry = JournalEntry.create!(
      journal: Journal.find_by(nature: :various, currency: purchase.currency),
      printed_on: purchase.invoiced_on + 15,
      items_attributes: {
        '0' => {
          name: 'Insurance care',
          account: purchase.supplier.account(:supplier),
          real_debit: purchase.amount
        },
        '1' => {
          name: 'Insurance care',
          account: Account.find_or_create_by_number('123456'),
          real_credit: purchase.amount
        }
      }
    )

    Regularization.create!(affair: purchase.affair, journal_entry: journal_entry)

    check_closed_state(purchase.affair)
  end

  # Creates a purchase and check affair informations
  def new_valid_purchases_invoice
    supplier = entities(:entities_005)
    journal = Journal.find_by(nature: :purchases)
    nature = PurchaseNature.find_or_initialize_by(
      with_accounting: true,
      journal: journal,
      currency: journal.currency
    )
    nature.name ||= 'Purchases baby!'
    nature.save!
    items = (0..4).to_a.map do |index|
      PurchaseItem.new(
        quantity: 1 + rand(20),
        unit_pretax_amount: 10 + (100 * rand).round(2),
        variant: ProductNatureVariant.where(
          category: ProductNatureCategory.where(purchasable: true)
        ).offset(index).first,
        tax: Tax.all.sample
      )
    end
    purchase = Purchase.create!(supplier: supplier, nature: nature, type: 'PurchaseInvoice', items: items)
    assert purchase.amount > 0, "Purchase amount should be greater than 0. Got: #{purchase.amount.inspect}"
    purchase.reload
    assert purchase.affair, 'An affair should be present after invoicing'
    assert purchase.journal_entry, 'A journal entry should exists after purchase invoicing'
    assert_equal purchase.affair.credit, purchase.amount, 'Purchase amount should match exactly affair debit'
    assert purchase.affair.unbalanced?,
           "Affair should not be balanced:\n" +
           purchase.affair.attributes.sort_by(&:first).map { |k, v| " - #{k}: #{v}" }.join("\n")
    assert purchase.affair.letterable_journal_entry_items.any?,
           "Affair should have letterable journal entry items:\n" +
           purchase.affair.deals.map { |d| " - #{d.class.name}: #{d.journal_entry.inspect}" }.join("\n")
    assert purchase.affair.journal_entry_items_unbalanced?,
           "Journal entry items should be unbalanced:\n" +
           purchase.affair.letterable_journal_entry_items.map { |i| " - #{i.account_number.ljust(14)} | #{i.debit.to_s.rjust(10)} | #{i.credit.to_s.rjust(10)}" }.join("\n")
    assert !purchase.affair.multi_thirds?
    assert !purchase.affair.journal_entry_items_already_lettered?

    # REVIEW: This should be confirmed by someone.
    # Test changed by @aquaj because it seems to be the desired behaviour
    # after @lcoq's modifications in code.
    # Can @burisu or @ionosphere confirm ?
    assert purchase.affair.letterable?
    purchase
  end
end
