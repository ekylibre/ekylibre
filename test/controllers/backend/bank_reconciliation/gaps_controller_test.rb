require 'test_helper'
module Backend
  module BankReconciliation
    # Handles creation of a 'Various op' Journal Entry.
    class GapsControllerTest < ActionController::TestCase
      setup do
        wipe_db
        setup_accountancy
        setup_items 1337
        signin
        setup_entries amount: 1500
      end

      test 'creates a \'various operation\' to match the gap between journal items and bank items' do
        post :create, bank_statement_id: @bank_statement,
                      bank_statement_item_ids: @tanks.map(&:id),
                      journal_entry_item_ids: @entry.items.last,
                      cash_id: @bank_statement.cash_id,
                      journal_id: @journal.id

        assert_equal(121, JournalEntry.last.items.find_by(account_id: @bank_statement.cash_account_id).balance)
      end

      test 'ensures the operation is properly lettered' do
        post :create, bank_statement_id: @bank_statement,
                      bank_statement_item_ids: @tanks.map(&:id),
                      journal_entry_item_ids: @entry.items.last,
                      cash_id: @bank_statement.cash_id,
                      journal_id: @journal.id

        assert_equal('A', JournalEntry.last.items.find_by(account_id: @bank_statement.cash_account_id).bank_statement_letter)
        assert_equal('A', @tanks.first.reload.letter)
        assert_equal('A', @tanks.last.reload.letter)
      end

      protected

      def signin
        role = Role.create!(name: 'Imperator')
        user = User.create!(first_name: 'Furiosa', last_name: 'Vuvalini',
                            email: 'furiosa@greenland.org',
                            password: 'youkilledtheworld',
                            administrator: true,
                            role: role)
        sign_in user
      end

      def wipe_db
        Payslip.delete_all
        IncomingPayment.delete_all
        OutgoingPayment.delete_all
        Regularization.delete_all

        JournalEntryItem.delete_all
        JournalEntry.delete_all
        BankStatementItem.delete_all
        BankStatement.delete_all
        Cash.delete_all
        PayslipNature.delete_all
        Entity.delete_all
        IncomingPaymentMode.delete_all
        OutgoingPaymentMode.delete_all

        Journal.delete_all
        Account.delete_all
      end

      def setup_accountancy(**options)
        ::Preference.set!(:bookkeep_automatically, options[:no_journal_entry].blank?)
        @journal  = Journal.create!(name: 'Pretty Journal')
        @fuel_act = Account.create!(name: 'Fuel', number: '002')
        @caps_act = Account.create!(name: 'Caps', number: '001')
        susp_one  = Account.create!(name: 'Susp', number: '5111')
        susp_two  = Account.create!(name: 'Susp', number: '5112')

        Account.create!(name: 'Gap', number: '982', usages: :other_usual_running_profits)
        Account.create!(name: 'Gap', number: '542', usages: :other_usual_running_expenses)

        @warrig_tank = Cash.create!(journal: @journal, main_account: @fuel_act, suspense_account: susp_one, name: 'War-rig\'s Tank')
        @caps_stash  = Cash.create!(journal: @journal, main_account: @caps_act, suspense_account: susp_two, name: 'Stash o\' Caps')
      end

      def setup_entries(amount: 42)
        @entry = JournalEntry.create!(
          journal: @journal,
          currency: @bank_statement.currency,
          printed_on: Time.zone.now,
          items_attributes:
            {
              '0' => {
                name: 'Test',
                real_debit: amount,
                account_id: @caps_act.id
              },
              '-1' => {
                name: 'TestBis',
                real_credit: amount,
                account_id: @fuel_act.id
              }
            }
        )
      end

      def setup_items(amount)
        amount_attr = (@payment_class == IncomingPayment ? :credit : :debit)

        now = Time.zone.now
        @bank_statement = BankStatement.create!(
          currency: 'EUR',
          number: 'Fuel level check',
          started_on: now - 10.days,
          stopped_on: now,
          cash: @warrig_tank
        )

        @tanks =  []
        @tanks << BankStatementItem.create!(
          name: 'Main tank',
          bank_statement: @bank_statement,
          transfered_on: now - 5.days,
          cash: @warrig_tank,
          amount_attr => 42
        )

        @tanks << BankStatementItem.create!(
          name: 'Backup tank',
          bank_statement: @bank_statement,
          transfered_on: now - 5.days,
          cash: @warrig_tank,
          amount_attr => amount
        )
      end
    end
  end
end
