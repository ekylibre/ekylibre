require 'test_helper'

module FixedAssetTest
  class FinancialYearConstrainedTest < Ekylibre::Testing::ApplicationTestCase
    test 'depreciations periods when fy start 01/03 and fa start after 6 months of fy' do
      create :financial_year, year: 2020, month: 3

      fa = create :fixed_asset, :linear, :yearly, started_on: Date.new(2020, 10, 29)

      assert fa.depreciations.to_a.drop(1).all? { |dep| dep.started_on.month == 3 }, "All (except first) depreciations periods should start on the same month as the begining of the FinancialYear"
    end

    test 'depreciations periods when fy start 01/03 and fa start 01/03' do
      create :financial_year, year: 2020, month: 3

      fa = create :fixed_asset, :linear, :yearly, started_on: Date.new(2020, 3, 1)

      assert fa.depreciations.to_a.all? { |dep| dep.started_on.month == 3 }, "All depreciations periods should start on the same month as the begining of the FinancialYear"
    end

    test 'depreciations periods when fy start on leap year 01/03 and fa start 01/03' do
      create :financial_year, year: 2019, month: 3

      fa = create :fixed_asset, :linear, :yearly, started_on: Date.new(2019, 3, 1)

      assert fa.depreciations.to_a.all? { |dep| dep.started_on.month == 3 }, "All depreciations periods should start on the same month as the begining of the FinancialYear"
    end

    test 'quaterly depreciations periods when fy start 01/03 and fa start 01/03' do
      create :financial_year, year: 2019, month: 3

      fa = create :fixed_asset, :linear, :quarterly, started_on: Date.new(2019, 3, 1)

      assert fa.depreciations.to_a.all? { |dep| dep.started_on.day == 1 }, "All depreciations periods should start on the same month as the begining of the FinancialYear"
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
