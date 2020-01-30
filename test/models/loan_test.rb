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
end
