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
# == Table: outgoing_payments
#
#  accounted_at      :datetime
#  affair_id         :integer
#  amount            :decimal(19, 4)   default(0.0), not null
#  bank_check_number :string
#  cash_id           :integer          not null
#  created_at        :datetime         not null
#  creator_id        :integer
#  currency          :string           not null
#  custom_fields     :jsonb
#  delivered         :boolean          default(FALSE), not null
#  downpayment       :boolean          default(FALSE), not null
#  id                :integer          not null, primary key
#  journal_entry_id  :integer
#  list_id           :integer
#  lock_version      :integer          default(0), not null
#  mode_id           :integer          not null
#  number            :string
#  paid_at           :datetime
#  payee_id          :integer          not null
#  position          :integer
#  responsible_id    :integer          not null
#  to_bank_at        :datetime         not null
#  type              :string
#  updated_at        :datetime         not null
#  updater_id        :integer
#

require 'test_helper'

class PurchasePaymentTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions

  test 'create without mode' do
    purchase_payment = PurchasePayment.new(
      amount: 56,
      payee: Entity.suppliers.first,
      delivered: true
    )
    # Should not save without exception raise
    refute purchase_payment.save
  end

  test 'delete outgoing payment delete journal entry' do
    now = Time.new(2016, 11, 17, 19)
    currency = FinancialYear.at(now).currency
    main = Account.find_or_create_by_number('512INR1')
    suspense = Account.find_or_create_by_number('511INR1')

    cash = Cash.create!(
      name: 'Namaste Bank',
      nature: :bank_account,
      currency: currency,
      main_account: main,
      suspend_until_reconciliation: true,
      suspense_account: suspense,
      journal: Journal.find_or_create_by!(nature: :bank, currency: currency, name: 'Namaste', code: 'Nam')
    )

    mode = OutgoingPaymentMode.find_by!(with_accounting: true)
    payer = Entity.normal.find_by!(client: true)
    responsible = User.find(1)

    payment = PurchasePayment.create!(mode: mode, payee: payer, amount: 504.12, delivered: true, currency: currency, cash: cash, responsible: responsible, to_bank_at: DateTime.new(2018, 1, 1))

    assert_not_nil payment
    assert_equal 504.12, payment.amount

    entry = payment.journal_entry

    assert_not_nil entry
    assert_equal 2, entry.items.count
    assert_equal 504.12, entry.real_debit, entry.inspect
    assert_equal 504.12, entry.real_credit, entry.inspect

    # Update with confirmed entry
    entry.confirm!

    payment.update!(amount: 405.21)
    entry_v2 = payment.journal_entry

    assert_not_nil entry_v2
    assert_not_equal entry, entry_v2

    entry.reload

    assert_equal 504.12, entry.real_debit, entry.inspect
    assert_equal 504.12, entry.real_credit, entry.inspect

    entry_v2.reload

    assert_equal 405.21, entry_v2.real_debit, entry_v2.inspect
    assert_equal 405.21, entry_v2.real_credit, entry_v2.inspect

    journal_entries_count = entry_v2.journal.entries.count
    payment.destroy
    new_journal_entries_count = entry_v2.journal.entries.count

    assert_equal journal_entries_count + 1, new_journal_entries_count
  end
end
