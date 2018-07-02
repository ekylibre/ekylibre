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
# == Table: economic_situations
#
#  accounting_balance          :decimal(, )
#  client_accounting_balance   :decimal(, )
#  client_trade_balance        :decimal(, )
#  created_at                  :datetime
#  creator_id                  :integer
#  id                          :integer          primary key
#  lock_version                :integer
#  supplier_accounting_balance :decimal(, )
#  supplier_trade_balance      :decimal(, )
#  trade_balance               :decimal(, )
#  updated_at                  :datetime
#  updater_id                  :integer
#
require 'test_helper'

class EconomicSituationTest < ActiveSupport::TestCase
  setup do
    @entity = Entity.create!(first_name: 'John', last_name: 'Doe')
    @client_account = Account.create!(name: 'John the client', number: '411123')
    @supplier_account = Account.create!(name: 'John the supplier', number: '401123')
    trash_account = Account.create!(name: 'Just needed', number: '666')
    @entity.update(client: true, client_account: @client_account)
    @entity.update(supplier: true, supplier_account: @supplier_account)

    Purchase.create!(
      currency: 'EUR',
      type: 'PurchaseInvoice',
      supplier: @entity,
      nature: PurchaseNature.create!(currency: 'EUR'),
      items_attributes: [
        {
          unit_pretax_amount: 12,
          quantity: 1,
          tax: Tax.create!(
            country: :fr,
            nature: :null_vat,
            name: 'Test',
            collect_account:  trash_account,
            deduction_account: trash_account
          ),
          variant: ProductNatureVariant.find_or_import!(:daucus_carotta).first,
          account: trash_account
        }
      ]
    )

    cash = Cash.create!(
      journal: Journal.create!(name: 'Ohloulou', code: 'Toto'),
      main_account: trash_account,
      name: 'Trésotest'
    )

    PurchasePayment.create!(
      currency: 'EUR',
      payee: @entity,
      responsible: User.create!(
        email: 'usertest@ekytest.test',
        password: '12345678',
        first_name: 'Test',
        last_name: 'Test',
        role: Role.create!(name: 'Test')
      ),
      to_bank_at: Time.now,
      amount: 9,
      mode: OutgoingPaymentMode.create!(
        name: 'TestMode',
        cash: cash
      )
    )

    sale = Sale.create!(
      client: @entity
    )

    SaleItem.create!(
      sale: sale,
      variant: ProductNatureVariant.find_or_import!(:daucus_carotta).first,
      unit_pretax_amount: 8,
      tax: Tax.create!(
        country: 'fr',
        nature: :null_vat,
        name: 'Test2',
        collect_account: trash_account,
        deduction_account: trash_account
      ),
      quantity: 1,
      amount: 8
    )

    IncomingPayment.create!(
      amount: 11,
      currency: 'EUR',
      payer: @entity,
      mode: IncomingPaymentMode.create!(
        name: 'IModeTest',
        cash: cash
      )
    )

    JournalEntry.create!(
      currency: 'EUR',
      journal: Journal.create!(name: 'JournalTest', code: 'TKT'),
      real_currency: 'EUR',
      number: '0420',
      printed_on: Time.now,
      items_attributes: [
        {
          real_credit: 10,
          entry_number: '4124',
          name: 'Item 1',
          account: @client_account
        },
        {
          real_debit: 10,
          entry_number: '4111',
          name: 'Item 2',
          account: trash_account
        }
      ]
    )

    JournalEntry.create!(
      currency: 'EUR',
      journal: Journal.create!(name: 'Yolo', code: 'Swag'),
      real_currency: 'EUR',
      number: '0420',
      printed_on: Time.now,
      items_attributes: [
        {
          real_debit: 7,
          entry_number: '4124',
          name: 'Item 1',
          account: @supplier_account
        },
        {
          real_credit: 7,
          entry_number: '4111',
          name: 'Item 2',
          account: trash_account
        }
      ]
    )
  end

  test 'at creation entity should have a balance of 0' do
    jack = Entity.create!(first_name: 'Jack', last_name: 'Black')
    assert jack.economic_situation
    assert_equal 0, jack.economic_situation[:client_accounting_balance]
    assert_equal 0, jack.economic_situation[:supplier_accounting_balance]
    assert_equal 0, jack.economic_situation[:accounting_balance]
    assert_equal 0, jack.economic_situation[:client_trade_balance]
    assert_equal 0, jack.economic_situation[:supplier_trade_balance]
    assert_equal 0, jack.economic_situation[:trade_balance]
  end

  test 'entities\' accounting balance is computed' do
    assert_equal 3, @entity.economic_situation[:accounting_balance]
  end

  test 'entities\' trade balance is computed correctly' do
    assert_equal 6, @entity.economic_situation[:trade_balance]
  end

  test 'entities\' client accounting balance is computed correctly' do
    assert_equal 10, @entity.economic_situation[:client_accounting_balance]
  end

  test 'entities\' supplier accounting balance is computed correctly' do
    assert_equal -7, @entity.economic_situation[:supplier_accounting_balance]
  end

  test 'entities\' client trade balance is computed correctly' do
    assert_equal 3, @entity.economic_situation[:client_trade_balance]
  end

  test 'entities\' supplier trade balance is computed correctly' do
    assert_equal 3, @entity.economic_situation[:supplier_trade_balance]
  end

  test 'entitites whose accounting and trade balance don\'t match can be found in #unbalanced scope' do
    assert EconomicSituation.unbalanced.pluck(:id).include? @entity.id
  end
end
