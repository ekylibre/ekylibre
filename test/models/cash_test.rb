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
# == Table: cashes
#
#  bank_account_holder_name          :string
#  bank_account_key                  :string
#  bank_account_number               :string
#  bank_agency_address               :text
#  bank_agency_code                  :string
#  bank_code                         :string
#  bank_identifier_code              :string
#  bank_name                         :string
#  by_default                        :boolean          default(FALSE)
#  container_id                      :integer
#  country                           :string
#  created_at                        :datetime         not null
#  creator_id                        :integer
#  currency                          :string           not null
#  custom_fields                     :jsonb
#  enable_bookkeep_bank_item_details :boolean          default(FALSE)
#  iban                              :string
#  id                                :integer          not null, primary key
#  journal_id                        :integer          not null
#  last_number                       :integer
#  lock_version                      :integer          default(0), not null
#  main_account_id                   :integer          not null
#  mode                              :string           default("iban"), not null
#  name                              :string           not null
#  nature                            :string           default("bank_account"), not null
#  owner_id                          :integer
#  spaced_iban                       :string
#  suspend_until_reconciliation      :boolean          default(FALSE), not null
#  suspense_account_id               :integer
#  updated_at                        :datetime         not null
#  updater_id                        :integer
#

require 'test_helper'

class CashTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions

  test "next reconciliation letters on a cash without bank statements starts from 'A'" do
    cash = cashes(:cashes_003)
    assert_equal %w[A B C], cash.next_reconciliation_letters.take(3)
  end

  test 'next reconciliation letters on a cash with bank statements starts from the letter succeeding the last reconciliation letter of the cash' do
    cash = cashes(:cashes_001)
    assert_equal %w[G], cash.next_reconciliation_letters.take(1)
  end

  test 'next reconciliation letters on a cash with bank statements can skip a letter if its already present' do
    cash = cashes(:cashes_001)
    assert_equal %w[G K L], cash.next_reconciliation_letters.take(3)
  end

  test 'valid if bank_account and valid iban' do
    assert cashes(:cashes_001).valid?
  end

  test 'invalid if bank_account and invalid iban value' do
    cash = cashes(:cashes_001)
    cash.iban = 'invalid_iban'
    assert_not cash.valid?
    assert_not_nil cash.errors.messages[:iban]
  end

  test 'invalid if bank_account and invalid iban length of 3' do
    cash = cashes(:cashes_001)
    cash.iban = '123'
    assert_not cash.valid?
    assert_not_nil cash.errors.messages[:iban]
  end

  test 'invalid if bank_account and invalid iban length of 35' do
    cash = cashes(:cashes_001)
    cash.iban = 'a' * 35
    assert_not cash.valid?
    assert_not_nil cash.errors.messages[:iban]
  end

  test 'valid if bank_account and iban blank' do
    cash = cashes(:cashes_001)
    cash.iban = ''
    assert cash.valid?
  end

  test 'valid if not bank_account and invalid iban value' do
    cash = cashes(:cashes_001)
    cash.nature = :cash_box
    cash.iban = 'invalid_iban'
    assert cash.valid?
  end

  test 'accounts with or without suspense' do
    main = Account.find_or_create_by_number('512001')
    assert main
    suspense = Account.find_or_create_by_number('511001')
    assert suspense

    currency = 'JPY'
    cash = Cash.create!(
      name: '¡Banky!',
      nature: :bank_account,
      currency: currency,
      main_account: main,
      suspense_account: suspense,
      journal: Journal.find_or_create_by(name: 'Banko', nature: :bank, currency: currency)
    )
    assert_equal main, cash.account

    cash.update!(suspend_until_reconciliation: true)

    assert_equal suspense, cash.account
  end
end
