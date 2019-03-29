require 'test_helper'
module Backend
  class QuickPurchasesControllerTest < ActionController::TestCase
    setup do
      OutgoingPayment.delete_all
      Payslip.delete_all
      PayslipNature.delete_all
      Journal.delete_all
      Account.delete_all
      Cash.delete_all
      BankStatement.delete_all
      BankStatementItem.delete_all
      PurchaseNature.delete_all
      PurchaseAffair.destroy_all
      OutgoingPaymentMode.delete_all
      Entity.delete_all
      Purchase.delete_all
      PurchasePayment.delete_all
      Tax.delete_all
      Role.delete_all
      User.delete_all

      role        = Role.create!(name: 'Imperator')
      user        = User.create!(first_name: 'Furiosa', last_name: 'Vuvalini', email: 'furiosa@greenland.org', password: 'youkilledtheworld', role: role)
      sign_in user

      journal     = Journal.create!(name: 'The Record')
      caps_act    = Account.create!(name: 'Caps', number: '001')
      fuel_act    = Account.create!(name: 'Fuel', number: '6')
      citadel_act = Account.create!(name: 'Citadel', number: '003')
      caps_stash  = Cash.create!(journal: journal, main_account: caps_act, name: 'Stash o\' Caps')
      interceptor = Cash.create!(journal: journal, main_account: fuel_act, name: 'Interceptor\'s Tank')
      @fuel_level = BankStatement.create!(currency: 'EUR', number: 'Fuel level check', started_on: Time.zone.now - 10.days, stopped_on: Time.zone.now, cash: interceptor)
      @tanks      = []
      @tanks << BankStatementItem.create!(
        name: 'Main tank',
        bank_statement: @fuel_level,
        transfered_on: Time.zone.now - 5.days,
        debit: 42
      )
      @tanks << BankStatementItem.create!(
        name: 'Backup tank',
        bank_statement: @fuel_level,
        transfered_on: Time.zone.now - 5.days,
        debit: 1337
      )

      @citadels   = Tax.create!(name: 'Citadel\'s tax', country: 'au', deduction_account: fuel_act, collect_account: citadel_act, nature: :normal_vat)

      @nature     = PurchaseNature.create!(currency: 'EUR', name: 'Perishables')

      @diesel     = OutgoingPaymentMode.create!(cash: interceptor, with_accounting: true, name: 'Diesel')
      @caps       = OutgoingPaymentMode.create!(cash: caps_stash,  with_accounting: true, name: 'Caps')

      @max        = Entity.create!(first_name: 'Max', last_name: 'Rockatansky', nature: :contact)

      @deal       = Purchase.create!(supplier: @max, nature: @nature, currency: 'EUR')
      @carrots    = ProductNatureVariant.import_from_nomenclature :carrot
      @payment    = PurchasePayment.create!(amount: 4242, currency: 'EUR', payee: @max, mode: @diesel, responsible: user, to_bank_at: Time.zone.now - 5.days)

      @deal.items.create!(variant_id: @carrots.id,
                          quantity: 500,
                          amount: 4242,
                          tax_id: @citadels.id,
                          reduction_percentage: 0,
                          unit_pretax_amount: 4242 / 500.0)

      ::Preference.set!(:bookkeep_automatically, true)
    end

    # TODO: Re-activate the following test

    # test 'returns a bad_request when nature isn\'t given' do
    #   get *complete_request(:new, except: :nature_id)
    #   assert_response :bad_request
    # end

    # TODO: Re-activate the following test

    # test 'can handle missing bank_statement_items' do
    #   get *complete_request(:new, except: :bank_statement_item_ids)
    #   assert_response :success

    #   # From existing
    #   post *complete_request(:create, except: :bank_statement_item_ids,
    #                                   modes: {
    #                                     trade: :existing,
    #                                     payment: :existing
    #                                   })
    #   assert_response :redirect
    #   assert_equal @payment, @deal.affair.purchase_payments.first

    #   # From new data
    #   post *complete_request(:create, except: :bank_statement_item_ids,
    #                                   modes: {
    #                                     trade: :new,
    #                                     payment: :new
    #                                   })

    #   assert_response :redirect
    #   affair = PurchaseAffair.find(@response.redirect_url.split('/').last)
    #   assert_equal 13.79, affair.purchases.first.items.first.unit_pretax_amount
    #   assert_equal 1379,  affair.purchase_payments.first.amount
    # end

    # TODO: Re-activate the following test

    # test 'letters on existing purchase/payment' do
    #   get *complete_request(:new)
    #   assert_response :success

    #   post *complete_request(:create, modes: {
    #                            trade: :existing,
    #                            payment: :existing
    #                          },
    #                                   matching: {
    #                                     amount: true,
    #                                     cash:   true
    #                                   })
    #   assert_response :redirect
    #   assert_equal @payment, @deal.affair.purchase_payments.first

    #   payment_letters = @payment.journal_entry.items
    #                             .where(account_id: @fuel_level.cash_account_id) # Only matching line is lettered
    #                             .pluck(:bank_statement_letter)
    #                             .compact.uniq
    #   assert_equal @tanks.each(&:reload).map(&:letter).uniq, payment_letters
    # end

    # TODO: Re-activate the following test

    # test 'letters on new purchase/payment' do
    #   get *complete_request(:new)
    #   assert_response :success

    #   post *complete_request(:create, modes: {
    #                            trade: :new,
    #                            payment: :new
    #                          },
    #                                   matching: {
    #                                     amount: true,
    #                                     cash:   true
    #                                   })

    #   assert_response :redirect
    #   affair = PurchaseAffair.find(@response.redirect_url.split('/').last)
    #   payment = affair.purchase_payments.first
    #   payment_letters = payment.journal_entry.items
    #                            .where(account_id: @fuel_level.cash_account_id) # Only matching line is lettered
    #                            .pluck(:bank_statement_letter)
    #                            .compact.uniq

    #   assert_equal 13.79, affair.purchases.first.items.first.unit_pretax_amount
    #   assert_equal 1379,  affair.purchase_payments.first.amount
    #   assert_equal @tanks.each(&:reload).map(&:letter).uniq, payment_letters
    # end

    # TODO: Re-activate following test

    # test 'doesn\'t letter when amounts don\'t match' do
    #   get *complete_request(:new)
    #   assert_response :success

    #   post *complete_request(:create, modes: {
    #                            trade: :existing,
    #                            payment: :existing
    #                          },
    #                                   matching: {
    #                                     amount: false,
    #                                     cash:   true
    #                                   })
    #   assert_response :redirect
    #   assert_equal @payment, @deal.affair.purchase_payments.first

    #   payment_letters = @payment.journal_entry.items
    #                             .where(account_id: @fuel_level.cash_account_id) # Only matching line is lettered
    #                             .pluck(:bank_statement_letter)
    #                             .compact.uniq
    #   assert_empty @tanks.map(&:letter).compact.uniq
    #   assert_empty payment_letters

    #   post *complete_request(:create, modes: {
    #                            trade: :new,
    #                            payment: :new
    #                          },
    #                                   matching: {
    #                                     amount: false,
    #                                     cash:   true
    #                                   })

    #   assert_response :redirect
    #   affair = PurchaseAffair.find(@response.redirect_url.split('/').last)
    #   payment = affair.purchase_payments.first
    #   payment_letters = payment.journal_entry.items
    #                            .where(account_id: @fuel_level.cash_account_id) # Only matching line is lettered
    #                            .pluck(:bank_statement_letter)
    #                            .compact.uniq

    #   assert_equal 12.50, affair.purchases.first.items.first.unit_pretax_amount
    #   assert_equal 1250,  affair.purchase_payments.first.amount
    #   assert_empty @tanks.map(&:letter).compact.uniq
    #   assert_empty payment_letters
    # end

    # TODO: Re-activate following test
    # test 'doesn\'t letter when cash modes don\'t match' do
    #   get *complete_request(:new)
    #   assert_response :success

    #   post *complete_request(:create, modes: {
    #                            trade: :existing,
    #                            payment: :existing
    #                          },
    #                                   matching: {
    #                                     amount: false,
    #                                     cash:   true
    #                                   })
    #   assert_response :redirect
    #   assert_equal @payment, @deal.affair.purchase_payments.first

    #   payment_letters = @payment.journal_entry.items
    #                             .where(account_id: @fuel_level.cash_account_id) # Only matching line is lettered
    #                             .pluck(:bank_statement_letter)
    #                             .compact.uniq
    #   assert_empty @tanks.map(&:letter).compact.uniq
    #   assert_empty payment_letters

    #   post *complete_request(:create, modes: {
    #                            trade: :new,
    #                            payment: :new
    #                          },
    #                                   matching: {
    #                                     amount: true,
    #                                     cash:   false
    #                                   })

    #   assert_response :redirect
    #   affair = PurchaseAffair.find(@response.redirect_url.split('/').last)
    #   payment = affair.purchase_payments.first
    #   payment_letters = payment.journal_entry.items
    #                            .where(account_id: @fuel_level.cash_account_id) # Only matching line is lettered
    #                            .pluck(:bank_statement_letter)
    #                            .compact.uniq

    #   assert_equal 13.79, affair.purchases.first.items.first.unit_pretax_amount
    #   assert_equal 1379,  affair.purchase_payments.first.amount
    #   assert_empty @tanks.map(&:letter).compact.uniq
    #   assert_empty payment_letters
    # end

    # TODO: Re-activate follwoing test

    # test 'doesn\'t letter when neither cash modes nor amounts match' do
    #   get *complete_request(:new)
    #   assert_response :success

    #   post *complete_request(:create, modes: {
    #                            trade: :existing,
    #                            payment: :existing
    #                          },
    #                                   matching: {
    #                                     amount: false,
    #                                     cash:   false
    #                                   })
    #   assert_response :redirect
    #   assert_equal @payment, @deal.affair.purchase_payments.first

    #   payment_letters = @payment.journal_entry.items
    #                             .where(account_id: @fuel_level.cash_account_id) # Only matching line is lettered
    #                             .pluck(:bank_statement_letter)
    #                             .compact.uniq
    #   assert_empty @tanks.map(&:letter).compact.uniq
    #   assert_empty payment_letters

    #   post *complete_request(:create, modes: {
    #                            trade: :new,
    #                            payment: :new
    #                          },
    #                                   matching: {
    #                                     amount: false,
    #                                     cash:   false
    #                                   })

    #   assert_response :redirect
    #   affair = PurchaseAffair.find(@response.redirect_url.split('/').last)
    #   payment = affair.purchase_payments.first
    #   payment_letters = payment.journal_entry.items
    #                            .where(account_id: @fuel_level.cash_account_id) # Only matching line is lettered
    #                            .pluck(:bank_statement_letter)
    #                            .compact.uniq

    #   assert_equal 12.50, affair.purchases.first.items.first.unit_pretax_amount
    #   assert_equal 1250,  affair.purchase_payments.first.amount
    #   assert_empty @tanks.map(&:letter).compact.uniq
    #   assert_empty payment_letters
    # end

    protected

    def complete_request(action, except: nil, **args)
      params = args.present? ? send(:"complete_#{action}_params", **args) : send(:"complete_#{action}_params")
      [action.to_sym, params.except(except)]
    end

    def complete_new_params
      { bank_statement_item_ids: @tanks.map(&:id), nature_id: @nature.id }
    end

    def complete_create_params(modes: { trade: :new, payment: :new }, matching: { cash: true, amount: true })
      amount = matching[:amount] ? 1379 : 1250
      mode   = matching[:cash]   ? @diesel : @caps
      @deal.reload
      @deal.update!(amount: amount)
      @deal.items.first.update!(amount: amount, unit_pretax_amount: amount / 500.0)
      @payment.reload
      @payment.update!(amount: amount, mode_id: mode.id)
      {
        'mode-trade': modes[:trade],
        'mode-payment': modes[:payment],
        affair: {
          trade_id: @deal.id,
          third_id: @max.id,
          payment_id: @payment.id
        },
        trade: {
          invoiced_at: Time.zone.now,
          nature_id: @nature.id,
          items_attributes: [{
            variant_id: @carrots,
            quantity: 100,
            amount: amount,
            tax_id: @citadels.id,
            reduction_percentage: 0,
            unit_pretax_amount: amount / 100.0
          }]
        },
        payment: {
          mode_id: mode,
          amount: amount,
          bank_statement_item_ids: @tanks.map(&:id)
        }
      }
    end
  end
end
