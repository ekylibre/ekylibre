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
# == Table: incoming_payments
#
#  accounted_at          :datetime
#  affair_id             :integer
#  amount                :decimal(19, 4)   not null
#  bank_account_number   :string
#  bank_check_number     :string
#  bank_name             :string
#  codes                 :jsonb
#  commission_account_id :integer
#  commission_amount     :decimal(19, 4)   default(0.0), not null
#  created_at            :datetime         not null
#  creator_id            :integer
#  currency              :string           not null
#  custom_fields         :jsonb
#  deposit_id            :integer
#  downpayment           :boolean          default(TRUE), not null
#  id                    :integer          not null, primary key
#  journal_entry_id      :integer
#  lock_version          :integer          default(0), not null
#  mode_id               :integer          not null
#  number                :string
#  paid_at               :datetime
#  payer_id              :integer
#  provider              :jsonb
#  providers             :jsonb
#  receipt               :text
#  received              :boolean          default(TRUE), not null
#  responsible_id        :integer
#  scheduled             :boolean          default(FALSE), not null
#  to_bank_at            :datetime         not null
#  updated_at            :datetime         not null
#  updater_id            :integer
#

require 'test_helper'

class IncomingPaymentTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions

  test 'bookkeeping without commission' do
    mode = IncomingPaymentMode.find_by!(with_accounting: true, with_commission: false)
    payer = Entity.normal.find_by!(client: true)
    payment = IncomingPayment.create!(mode: mode, payer: payer, amount: 504.12, received: true, to_bank_at: DateTime.new(2018, 1, 1))
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
    assert_not_equal entry, entry_v2
    entry.reload
    assert_equal 504.12, entry.real_debit, entry.inspect
    assert_equal 504.12, entry.real_credit, entry.inspect
    entry_v2.reload
    assert_equal 405.21, entry_v2.real_debit, entry_v2.inspect
    assert_equal 405.21, entry_v2.real_credit, entry_v2.inspect
    entry.close!
    # Update with closed entry
    entry_v2.confirm!
    entry_v2.close!
    assert_raise Ekylibre::Record::RecordNotUpdateable do
      payment.update!(amount: 450.21)
    end
  end

  test 'create without mode' do
    incoming_payment = IncomingPayment.new(
      amount: 56,
      payer: Entity.clients.first,
      received: true
    )
    # Should not save without exception raise
    refute incoming_payment.save
  end

  test 'delete incoming payment delete journal entry' do
    mode = IncomingPaymentMode.find_by!(with_accounting: true, with_commission: false)
    payer = Entity.normal.find_by!(client: true)
    payment = IncomingPayment.create!(mode: mode, payer: payer, amount: 504.12, received: true, to_bank_at: DateTime.new(2018, 1, 1))

    assert_not_nil payment
    assert_equal 504.12, payment.amount

    entry = payment.journal_entry

    assert_not_nil entry
    assert_equal 2, entry.items.count
    assert_equal 504.12, entry.real_debit, entry.inspect
    assert_equal 504.12, entry.real_credit, entry.inspect

    # Update with confirmed entry
    entry.confirm!

    journal_entries_count = entry.journal.entries.count
    payment.destroy
    new_journal_entries_count = entry.journal.entries.count

    assert_equal journal_entries_count + 1, new_journal_entries_count

    cancel_entry = entry.journal.entries.reorder(id: :desc).first

    assert_equal entry.items.count, cancel_entry.items.count, 'Cancel entry should have the same count of items of the cancelled entry'

    entry.items.each do |item|
      candidates_count = cancel_entry.items.where(
        account: item.account,
        debit:  item.credit,
        credit: item.debit,
        real_debit:  item.real_credit,
        real_credit: item.real_debit,
        absolute_debit:  item.absolute_credit,
        absolute_credit: item.absolute_debit
      ).count
      assert_equal 1, candidates_count, "Could not find reversed item in cancel entry for #{item.account.number}"
    end
  end
end
