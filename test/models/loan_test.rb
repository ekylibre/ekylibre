# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2021 Ekylibre SAS
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
# == Table: loans
#
#  accountable_repayments_started_on :date
#  accounted_at                      :datetime
#  amount                            :decimal(19, 4)   not null
#  bank_guarantee_account_id         :integer
#  bank_guarantee_amount             :integer
#  cash_id                           :integer          not null
#  created_at                        :datetime         not null
#  creator_id                        :integer
#  currency                          :string           not null
#  custom_fields                     :jsonb
#  id                                :integer          not null, primary key
#  initial_releasing_amount          :boolean          default(FALSE), not null
#  insurance_account_id              :integer
#  insurance_percentage              :decimal(19, 4)   not null
#  insurance_repayment_method        :string
#  interest_account_id               :integer
#  interest_percentage               :decimal(19, 4)   not null
#  journal_entry_id                  :integer
#  lender_id                         :integer          not null
#  loan_account_id                   :integer
#  lock_version                      :integer          default(0), not null
#  name                              :string           not null
#  ongoing_at                        :datetime
#  provider                          :jsonb
#  repaid_at                         :datetime
#  repayment_duration                :integer          not null
#  repayment_method                  :string           not null
#  repayment_period                  :string           not null
#  shift_duration                    :integer          default(0), not null
#  shift_method                      :string
#  started_on                        :date             not null
#  state                             :string
#  updated_at                        :datetime         not null
#  updater_id                        :integer
#  use_bank_guarantee                :boolean
#
require 'test_helper'

class LoanTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions

  setup do
    @loan_account = Account.find_or_create_by_number('164')
    @interest_account = Account.find_or_create_by_number('6611')
    @insurance_account = Account.find_or_create_by_number('616')
    main = Account.find_or_create_by_number('512001')
    suspense = Account.find_or_create_by_number('511001')
    currency = 'EUR'
    @user = User.first

    @cash = Cash.create!(
      name: '¡Banky!',
      nature: :bank_account,
      currency: currency,
      main_account: main,
      suspense_account: suspense,
      journal: Journal.find_or_create_by(nature: :bank, currency: currency)
    )

    @entity = Entity.create!(last_name: 'CA')
    @on = Date.parse('2017-01-01')
    @bookkeep_until = Date.parse('2020-12-31')

    attributes = {
      name: 'FENDT 820',
      cash: @cash,
      lender: @entity,
      insurance_repayment_method: :initial,
      repayment_method: :constant_amount,
      shift_method: :immediate_payment,
      ongoing_at: @on.to_time,
      started_on: @on,
      shift_duration: 0,
      loan_account: @loan_account,
      interest_account: @interest_account,
      insurance_account: @insurance_account,
      use_bank_guarantee: false
    }

    @loan = Loan.new(attributes)
  end

  test 'new 120 months loan' do
    l = @loan

    l.repayment_period = :month
    l.repayment_duration = 120
    l.amount = 100_000.00
    l.interest_percentage = 1.2
    l.insurance_percentage = 0.2
    l.save!
    l.reload

    assert_equal 120, l.repayments.count
    assert_equal 901.42, l.repayments.first.amount.to_f
    assert_equal 784.75, l.repayments.first.base_amount.to_f
    assert_equal 100.00, l.repayments.first.interest_amount.to_f
    assert_equal 16.67, l.repayments.first.insurance_amount.to_f
    assert_equal 901.32, l.repayments.last.amount.to_f
    assert_equal 883.77, l.repayments.last.base_amount.to_f
    assert_equal 0.88, l.repayments.last.interest_amount.to_f
    assert_equal 16.67, l.repayments.last.insurance_amount.to_f
  end

  test 'new 10 years loan' do
    l = @loan

    l.repayment_period = :year
    l.repayment_duration = 10
    l.amount = 100_000.00
    l.interest_percentage = 1.2
    l.insurance_percentage = 0.2
    l.save!

    l.reload

    assert_equal 10, l.repayments.count
    # FIXME: Write comprehensive tests for yearly method
    # assert_equal 901.42, l.repayments.first.amount.to_f
    # assert_equal 784.75, l.repayments.first.base_amount.to_f
    # assert_equal 100.00, l.repayments.first.interest_amount.to_f
    # assert_equal 16.67, l.repayments.first.insurance_amount.to_f
    # assert_equal 901.32, l.repayments.last.amount.to_f
    # assert_equal 883.77, l.repayments.last.base_amount.to_f
    # assert_equal 0.88, l.repayments.last.interest_amount.to_f
    # assert_equal 16.67, l.repayments.last.insurance_amount.to_f
  end

  test 'update loan when state is ongoing' do
    l = @loan

    l.repayment_period = :year
    l.repayment_duration = 10
    l.amount = 100_000.00
    l.interest_percentage = 1.2
    l.insurance_percentage = 0.2
    l.save!
    assert_equal 10, l.repayments.count
    l.confirm(ongoing_at: @on.to_time, current_user: @user)
    assert_equal 'ongoing', l.state
    l.reload
    l.amount = 200_000.00
    l.repayment_duration = 20
    l.save!
    l.reload
    assert_equal 20, l.repayments.count
  end

  test 'update / delete loan when state is ongoing depending on loan entry state' do
    l = @loan

    l.repayment_period = :year
    l.repayment_duration = 10
    l.amount = 100_000.00
    l.interest_percentage = 1.2
    l.insurance_percentage = 0.2
    l.save!
    assert_equal 10, l.repayments.count
    l.confirm(ongoing_at: @on.to_time, current_user: @user)
    l.reload
    assert_equal 'ongoing', l.state
    assert l.destroyable?
    assert l.updateable?
    # validate journal_entry
    l.journal_entry.update(state: :confirmed, validated_at: @on.to_time)
    JournalEntryItem.where(entry_id: l.journal_entry.id).update_all(state: :confirmed)
    l.reload
    refute l.updateable?
    refute l.destroyable?
  end

  test 'update / delete or not loan when state is ongoing depending on loan_repaymments entries state' do
    l = @loan

    l.repayment_period = :year
    l.repayment_duration = 10
    l.amount = 100_000.00
    l.interest_percentage = 1.2
    l.insurance_percentage = 0.2
    l.save!
    l.confirm(ongoing_at: @on.to_time, current_user: @user)
    l.reload
    # validate journal_entry
    Loan.bookkeep_repayments(until: @bookkeep_until)
    JournalEntry.where(id: l.repayments.pluck(:journal_entry_id)).update_all(state: :confirmed, validated_at: @bookkeep_until.to_time)
    JournalEntryItem.where(entry_id: l.repayments.pluck(:journal_entry_id)).update_all(state: :confirmed)
    l.reload
    refute l.updateable?
    refute l.destroyable?
  end

end
