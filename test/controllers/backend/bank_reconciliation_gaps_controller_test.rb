require 'test_helper'
module Backend
  class BankReconciliationGapsControllerTest < ActionController::TestCase
    setup do
      wipe_db
      setup_accountancy
      setup_items 1337
    end

    test 'creates a \'various operation\' to match the gap between journal items and bank items' do
      setup_entries amount: 1338
      post :create, bank_statement_id: @bank_statement, journal_entry_item_ids: @entry.items.first
      byebug
    end

    def wipe_db
      Journal.delete_all
      Account.delete_all
      Cash.delete_all
      BankStatement.delete_all
      BankStatementItem.delete_all
      Entity.delete_all
      IncomingPayment.delete_all
      IncomingPaymentMode.delete_all
      OutgoingPayment.delete_all
      OutgoingPaymentMode.delete_all
    end

    def setup_data(**options)
      wipe_db

      setup_accountancy(**options)
      setup_items(options[:amount_mismatch] ? 1336 : 1337)
      setup_entries
    end

    def setup_accountancy(**options)
      ::Preference.set!(:bookkeep_automatically, options[:no_journal_entry].blank?)
      @journal     = Journal.create!
      @fuel_act    = Account.create!(name: 'Fuel', number: '002')
      @caps_act    = Account.create!(name: 'Caps', number: '001')

      @warrig_tank = Cash.create!(journal: @journal, main_account: @fuel_act, name: 'War-rig\'s Tank')
      @caps_stash  = Cash.create!(journal: @journal, main_account: @caps_act, name: 'Stash o\' Caps')
    end

    def setup_entries(amount: 42)
      @entry = JournalEntry.create!(
        journal: @journal,
        currency: @fuel_level.currency,
        printed_on: Time.zone.now,
        items_attributes:
        {
          '0' => {
            name: 'Test',
            real_debit: amount,
            account_id: @fuel_act.id
          },
          '-1' => {
            name: 'TestBis',
            real_credit: amount,
            account_id: @caps_act.id
          }
        }
      )
    end

    def setup_items(amount)
      amount_attr = (@payment_class == IncomingPayment ? :credit : :debit)

      now = Time.zone.now
      @fuel_level = BankStatement.create!(
        currency: 'EUR',
        number: 'Fuel level check',
        started_on: now - 10.days,
        stopped_on: now,
        cash: @warrig_tank
      )

      @tanks =  []
      @tanks << BankStatementItem.create!(
        name: 'Main tank',
        bank_statement: @fuel_level,
        transfered_on: now - 5.days,
        amount_attr => 42
      )

      @tanks << BankStatementItem.create!(
        name: 'Backup tank',
        bank_statement: @fuel_level,
        transfered_on: now - 5.days,
        amount_attr => amount
      )
    end
  end
end
