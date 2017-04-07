require 'test_helper'

class EntityBalanceTest < ActiveSupport::TestCase
  setup do
    @entity = Entity.create!(first_name: 'John', last_name: 'Doe')
    @client_account = Account.create!(name: 'John the client', number: '411123')
    @supplier_account = Account.create!(name: 'John the supplier', number: '401123')
    trash_account = Account.create!(name: 'Just needed', number: '666')
    @entity.update(client: true, client_account: @client_account)
    @entity.update(supplier: true, supplier_account: @supplier_account)

    Purchase.create!(
      currency: 'EUR',
      supplier: @entity,
      nature: PurchaseNature.create!(currency: 'EUR'),
      items_attributes: [
        {
          unit_pretax_amount: '12',
          tax: Tax.create!(country: :fr,
                           nature: :null_vat,
                           name: 'Test',
                           collect_account:  trash_account,
                           deduction_account: trash_account),
          variant: ProductNatureVariant.find_or_import!(:daucus_carotta).first,
          account: trash_account
        }
      ]
    )

    cash = Cash.create!(
          journal: Journal.create!(name: 'Ohloulou', code: 'Toto'),
          main_account: trash_account,
          name: 'Trésotest')
    
    OutgoingPayment.create!(
      currency: 'EUR',
      payee: @entity,
      responsible: User.create!(email: 'usertest@ekytest.test',
                                password: '12345678',
                                first_name: 'Test',
                                last_name: 'Test',
                                role: Role.create!(name: 'Test')),
      to_bank_at: Time.now,
      amount: 9,
      mode: OutgoingPaymentMode.create!(
        name: 'TestMode',
        cash: cash))

    sale = Sale.create!(
      client: @entity
    )

    SaleItem.create!(
      sale: sale,
      variant: ProductNatureVariant.find_or_import!(:daucus_carotta).first,
      unit_pretax_amount: 8,
      tax: Tax.create!(country: 'fr',
                       nature: :null_vat,
                       name: 'Test2',
                       collect_account: trash_account,
                       deduction_account: trash_account),
      quantity: 1,
      amount: 8
    )
    
    IncomingPayment.create!(
      amount: 11,
      currency: 'EUR',
      payer: @entity,
      mode: IncomingPaymentMode.create!(name: 'IModeTest',
                                        cash: cash))

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
      ])

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
      ])
  end

  test 'at creation entity should have a balance of 0' do
    jack = Entity.create!(first_name: 'Jack', last_name: 'Black')
    assert jack.entity_balance
    assert_equal 0, jack.entity_balance[:client_accounting_balance]
    assert_equal 0, jack.entity_balance[:supplier_accounting_balance]
    assert_equal 0, jack.entity_balance[:accounting_balance]
    assert_equal 0, jack.entity_balance[:client_trade_balance]
    assert_equal 0, jack.entity_balance[:supplier_trade_balance]
    assert_equal 0, jack.entity_balance[:trade_balance]
  end

  test 'entities\' accounting balance is computed' do
    assert_equal 3, @entity.entity_balance[:accounting_balance]
  end

  test 'entities\' trade balance is computed correctly' do
    assert_equal 6, @entity.entity_balance[:trade_balance]
  end

  test 'entities\' client accounting balance is computed correctly' do
    assert_equal 10, @entity.entity_balance[:client_accounting_balance]
  end

  test 'entities\' supplier accounting balance is computed correctly' do
    assert_equal -7, @entity.entity_balance[:supplier_accounting_balance]
  end

  test 'entities\' client trade balance is computed correctly' do
    assert_equal 3, @entity.entity_balance[:client_trade_balance]
  end

  test 'entities\' supplier trade balance is computed correctly' do
    assert_equal 3, @entity.entity_balance[:supplier_trade_balance]
  end

  test 'entitites whose accounting and trade balance don\'t match can be found in #unbalanced scope' do
    assert EntityBalance.unbalanced.pluck(:id).include? @entity.id
  end
end
