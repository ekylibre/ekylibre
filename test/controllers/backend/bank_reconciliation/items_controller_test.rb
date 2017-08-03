# coding: utf-8

require 'test_helper'

# Tests if the whole period_start/end system works.
module ReconciliationPeriodTest
  extend ActiveSupport::Concern

  included do
    test 'period is set by default to ±20 days' do
      get :index, bank_statement_id: @bank_statement.id
      assert_equal @now.to_date - 25.days, ivar_value(:@period_start)
      assert_equal @now.to_date + 25.days, ivar_value(:@period_end)
    end

    test 'period can be set by params' do
      start = Date.new(2016, 12, 20)
      stop  = Date.new(2016, 12, 25)

      get :index, bank_statement_id: @bank_statement.id,
                  period_start: start.strftime('%Y-%m-%d'),
                  period_end:   stop.strftime('%Y-%m-%d')

      assert_equal start, ivar_value(:@period_start)
      assert_equal stop,  ivar_value(:@period_end)
    end

    test 'period is used to filter out entries' do
      start = @now - 5.days
      stop  = @now - 2.days
      get :index, bank_statement_id: @bank_statement.id,
                  period_start: start.strftime('%Y-%m-%d'),
                  period_end:   stop.strftime('%Y-%m-%d')
      assert_equal 1, ivar_value(:@items_grouped_by_date)
        .values.flatten
        .select { |item| item.is_a? JournalEntryItem }.count
    end
  end
end

# Rendering details
module ReconciliationRenderingTest
  extend ActiveSupport::Concern

  included do
    test 'reconciliation renders properly' do
      assert_nothing_raised { get :index, bank_statement_id: @bank_statement.id }
    end

    test 'we are redirected with a flash if we don\'t have any entry items' do
      JournalEntry.destroy_all
      get :index, bank_statement_id: @bank_statement.id
      assert_not_empty flash['notifications']
    end
  end
end

# Lettering tests
module AutoLetteringTest
  extend ActiveSupport::Concern

  included do
    test 'autoreconciliation letters entries' do
      get :index, bank_statement_id: @bank_statement.id
      entries = ivar_value(:@items_grouped_by_date).sort.first.last.select { |item| item.is_a? JournalEntryItem }
      assert_equal 'A', entries.first.bank_statement_letter
    end

    test 'autoreconciliation doesn\'t letter entries that are on another date' do
      get :index, bank_statement_id: @bank_statement.id
      entries = ivar_value(:@items_grouped_by_date).sort.last.last.select { |item| item.is_a? JournalEntryItem }
      assert_nil entries.first.bank_statement_letter
    end
  end
end

module Backend
  module BankReconciliation
    # Tests for BankReconciliation
    class ItemsControllerTest < ActionController::TestCase
      include ::ReconciliationPeriodTest
      include ::ReconciliationRenderingTest
      include ::AutoLetteringTest

      setup do
        empty_db
        signin

        @now     = Time.zone.now
        journal  = Journal.create!(name: 'Pretty Journal')
        fuel_act = Account.create!(name: 'Fuel', number: '6')
        caps_act = Account.create!(name: 'Caps', number: '5')
        bank_statement_setup(account: fuel_act, journal: journal)
        entry_setup(amount: 42, date: @now - 4.days,
                    journal: journal, bank_account: fuel_act,
                    ext_account: caps_act)
        entry_setup(amount: 1337, date: @now + 4.days,
                    journal: journal, bank_account: fuel_act,
                    ext_account: caps_act)
      end

      protected

      def empty_db
        [OutgoingPayment, OutgoingPaymentMode, Payslip, PayslipNature,
         Journal, Account, Cash, BankStatement,
         BankStatementItem, Role, User, Regularization,
         JournalEntryItem, JournalEntry].each(&:delete_all)
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
                                                    transfered_on: @now - 4.days,
                                                    debit: 1337)
      end

      def entry_setup(amount: 0, journal: nil, ext_account: nil, bank_account: nil, date: Time.zone.today)
        JournalEntry.create!(journal: journal, currency: 'EUR', printed_on: date,
                             items_attributes: {
                               '0' => {
                                 name: 'Test',
                                 real_debit: amount,
                                 account_id: ext_account.id
                               },
                               '-1' => {
                                 name: 'Testbis',
                                 real_credit: amount,
                                 account_id: bank_account.id
                               }
                             })
      end

      def ivar_value(name)
        @controller.instance_variable_get(name)
      end
    end
  end
end
