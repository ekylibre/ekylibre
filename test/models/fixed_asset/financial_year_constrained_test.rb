require 'test_helper'

module FixedAssetTest
  class FinancialYearConstrainedTest < Ekylibre::Testing::ApplicationTestCase

    test 'depreciations periods are computed correctly when the FinancialYear does not start the first day of the year' do
      create :financial_year, year: 2017, month: 3

      fa = create :fixed_asset, started_on: Date.new(2017, 3, 1)

      assert fa.depreciations.to_a.all? { |dep| dep.started_on.month == 3 }, "All depreciations periods should start on the same month as the begining of the FinancialYear"
    end


    test 'on_unclosed_periods? with closed journal' do
      create :financial_year, year: 2018

      fa = create :fixed_asset,
                  started_on: Date.new(2017, 5, 1)

      assert fa.journal.closed_on > fa.started_on
      assert_not fa.on_unclosed_periods?
    end

    test 'on_unclosed_periods? with opened journal' do
      @journal = create :journal
      create :financial_year, year: 2018

      fa = create :fixed_asset,
                  started_on: Date.new(2017, 5, 1),
                  journal: @journal

      assert fa.journal.closed_on < fa.started_on
      assert fa.on_unclosed_periods?
    end

  end
end