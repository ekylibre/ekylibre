require 'test_helper'

module FixedAssetTest
  class FixedAssetImportTest < Ekylibre::Testing::ApplicationTestCase

    setup do
      @journal = create :journal
      (2010..2015).each { |year| create :financial_year, year: year, state: :locked }
      [2016, 2017].each { |year| create :financial_year, year: year }
    end

    test 'enabling a FixedAssed on a date where no FinancialYear opened creates the correct journal entries' do
      waiting_account = Account.find_or_import_from_nomenclature :suspense

      fa = create :fixed_asset, :in_use, :yearly, :linear,
                  started_on: Date.new(2008,1,1),
                  amount: 50_000,
                  percentage: 10.00,
                  journal: @journal

      fa_je = fa.journal_entry

      assert fa_je.balanced?

      jeis_debit, jeis_credit = fa_je.items.partition { |e| e.debit > 0 }
      assert_equal 50_000, jeis_debit[0].debit
      assert_equal 50_000, jeis_credit[0].credit

      current_fy = FinancialYear.opened.first

      locked, opened = fa.depreciations.partition { |fad| fad.started_on < current_fy.started_on }

      locked.each do |dep|
        assert dep.locked?, "All depreciations before the first FinancialYear should be locked"
        assert dep.has_journal_entry?, "All locked depreciations should be automatically accounted"

        je = dep.journal_entry
        assert_equal Date.new(2016, 1, 1), je.printed_on, "The journal entry should be printed on at the begining of the first opened FinancialYear"

        debit, credit = je.items.partition { |i| i.debit > 0 }
        debit = debit.first
        credit = credit.first

        assert_equal 5_000, debit.debit, "The amount of the journal entry should be 5000"
        assert_equal 5_000, credit.credit, "The amount of the journal entry should be 5000"

        assert_equal waiting_account, debit.account, "The debit account should be the waiting account (471)"
        assert_equal fa.allocation_account, credit.account, "The credited account should be the allocation account of the linked FixedAsset"
      end

      assert_not opened.any?(&:locked?), "All depreciations after the first opened FinancialYear should not be locked"
      assert_not opened.any?(&:has_journal_entry?), "All depreciations after the first opened FinancialYear should not have a journal entry"
    end
  end
end
