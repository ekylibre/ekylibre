require 'test_helper'

module Sage
  module ISeven
    module JournalEntriesExchangerTest
      class JournalEntriesExchangerTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
        test 'import' do
          FinancialYear.delete_all
          create(:financial_year, year: 2018)
          Preference.set!(:account_number_digits, 9)
          exchanger = Sage::ISeven::JournalEntriesExchanger.build(fixture_files_path.join('imports', 'sage', 'i_seven', 'journal_entries.ecx'), options: { import_id: 1 })

          res = exchanger.run
          assert res.success?

          journal1 = Journal.find_by(name: "Ventes eaux-de-vie")
          assert journal1
          journal_entry_1 = journal1.entries.find_by(number: 1)
          item1 = journal_entry_1.items

          journal2 = Journal.find_by(name: "C.i.c. Ouest")
          journal_entry_2 = journal2.entries.find_by(number: 1)
          item2 = journal_entry_2.items
          cash_main_account = Cash.find_by(iban: 'FR1420041010050500013M02606').main_account.number

          assert_equal 2, journal1.entries.count
          assert_equal 1, journal2.entries.count
          assert_equal 4364.8, item1.where(account: Account.where(number: '707100000')).first.real_credit.to_f
          assert_equal 4363.49, item1.where(account: Account.where(number: '411008162')).first.real_debit.to_f
          assert_equal 1.06, item1.where(account: Account.where(number: '637800000')).first.real_debit.to_f
          assert_equal 0.25, item1.where(account: Account.where(number: '637801000')).first.real_debit.to_f

          assert_equal 4, journal_entry_1.items.count
          assert_equal 2, journal_entry_2.items.count
          assert_equal 282.18, item2.where(account: Account.where(number: '401000483')).first.real_debit.to_f
          assert_equal 282.18, item2.where(account: Account.where(number: '512300000')).first.real_credit.to_f
          assert_equal '512300000', cash_main_account
          assert Account.find_by(number: '401000483')
          assert Journal.find_by(code: "SAGC")
          assert Journal.find_by(code: "SAGF")
        end
      end
    end
  end
end
