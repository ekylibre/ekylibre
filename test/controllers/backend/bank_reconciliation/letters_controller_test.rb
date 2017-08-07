require 'test_helper'

module Backend
  module BankReconciliation
    # Tests the lettering/unlettering.
    class LettersControllerTest < ActionController::TestCase
      LETTER = 'B'.freeze

      setup do
        empty_db
        signin

        @now     = Time.zone.now
        journal  = Journal.create!(name: 'Pretty Journal')
        fuel_act = Account.create!(name: 'Fuel', number: '6')
        caps_act = Account.create!(name: 'Caps', number: '5')
        bank_statement_setup(account: fuel_act, journal: journal)
        entry_setup(amount: 42, date: @now - 4.days,
                    journal: journal, accounts: [caps_act, fuel_act])
        entry_setup(amount: 1337, date: @now + 4.days,
                    journal: journal, accounts: [caps_act, fuel_act],
                    letter: LETTER)
      end

      test 'can letter' do
        bank_forty_two    = @bank_statement.items.find_by(debit: 42)
        journal_forty_two = JournalEntryItem.find_by(real_credit: 42)
        assert_nil bank_forty_two.letter
        assert_nil journal_forty_two.bank_statement_letter

        post :create, format: :json,
                      cash_id: @bank_statement.cash_id,
                      bank_statement_items: [bank_forty_two],
                      journal_entry_items:  [journal_forty_two]

        new_letter = LETTER.next

        assert_equal new_letter, JSON(@response.body)['letter']
        assert_equal new_letter, bank_forty_two.reload.letter
        assert_equal new_letter, journal_forty_two.reload.bank_statement_letter
      end

      test 'can unletter' do
        bank_leet    =  @bank_statement.items.find_by(debit: 1337)
        journal_leet =  JournalEntryItem.find_by(real_credit: 1337)
        assert_equal LETTER, bank_leet.letter
        assert_equal LETTER, journal_leet.bank_statement_letter
        assert_equal @bank_statement, journal_leet.bank_statement

        xhr :delete, :destroy, format: :json,
                               id: @bank_statement.id,
                               letter: :B

        assert_equal LETTER, JSON(@response.body)['letter']

        assert_nil bank_leet.reload.letter
        assert_nil journal_leet.reload.bank_statement_letter
        assert_nil journal_leet.reload.bank_statement
      end

      protected

      def empty_db
        [OutgoingPayment, OutgoingPaymentMode, Payslip, PayslipNature,
         BankStatementItem, BankStatement, Cash,
         Role, User, Regularization,
         JournalEntryItem, JournalEntry, Journal, Account].each(&:delete_all)
      end

      def signin
        role = Role.create!(name: 'Imperator')
        user = User.create!(first_name: 'Furiosa', last_name: 'Vuvalini',
                            email: 'furiosa@greenland.org',
                            password: 'youkilledtheworld',
                            administrator: true,
                            role: role)
        sign_in user
      end

      def bank_statement_setup(journal: nil, account: nil)
        interceptor     = Cash.create!(journal: journal, main_account: account, name: 'Interceptor\'s Tank')
        @bank_statement = BankStatement.create!(currency: 'EUR', number: 'Fuel level check', started_on: @now - 5.days, stopped_on: @now + 5.days, cash: interceptor)
        @items          = []
        @items         << BankStatementItem.create!(name: 'Main tank',
                                                    bank_statement: @bank_statement,
                                                    transfered_on: @now - 4.days,
                                                    debit: 42)

        @items         << BankStatementItem.create!(name: 'Backup tank',
                                                    bank_statement: @bank_statement,
                                                    transfered_on: @now + 4.days,
                                                    debit: 1337,
                                                    letter: :B)
      end

      def entry_setup(amount: 0, journal: nil, accounts: [], date: Time.zone.today, letter: nil)
        JournalEntry.create!(journal: journal, currency: 'EUR', printed_on: date,
                             items_attributes: {
                               '0' => {
                                 name: 'Test',
                                 real_debit: amount,
                                 account_id: accounts.first.id,
                                 bank_statement_letter: letter
                               },
                               '-1' => {
                                 name: 'Testbis',
                                 real_credit: amount,
                                 account_id: accounts.last.id,
                                 bank_statement_letter: letter,
                                 bank_statement_id: letter ? @bank_statement.id : nil
                               }
                             })
      end
    end
  end
end
