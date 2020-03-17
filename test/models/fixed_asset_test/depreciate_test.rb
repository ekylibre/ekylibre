require 'test_helper'

module FixedAssetTest
  class DepreciateTest < Ekylibre::Testing::ApplicationTestCase
    setup do
      [2017, 2018].each { |year| create :financial_year, year: year }
    end

    test "successive depreciations" do
      fa = create :fixed_asset, :linear, :yearly,
                  amount: 150_000,
                  started_on: Date.new(2017, 5, 9),
                  percentage: 10.0

      assert fa.start_up

      # Initial depreciation
      assert_equal 1, FixedAsset.depreciate(until: Date.new(2017, 12, 31))
      fa.reload

      assert_equal 1, fa.depreciations.where(accountable: true).count
      dep, *other = fa.depreciations
      assert dep.journal_entry.present?
      assert dep.accountable?
      assert other.all? { |d| d.journal_entry.nil? }
      assert_not other.any? { |d| d.accountable? }

      # Lock financial year
      FinancialYearLocker.new.lock!(FinancialYear.on(Date.new(2017, 1, 2)))

      # Next year, depreciate again
      assert_equal 1, FixedAsset.depreciate(until: Date.new(2018, 12, 31))
      fa.reload

      _, dep, *other = fa.depreciations
      assert dep.accountable?, "Depreciation should be accountable"
      assert dep.journal_entry.present?, "Depreciation should have a journal_entry"
      assert_not other.any? { |d| d.accountable? }, "The remaining depreciations should not be accountable"
      assert other.all? { |d| d.journal_entry.nil? }, "The remaining depreciations should not have a journal_entry"

      # Depreciations without financial years should not be modified
      assert_equal 0, FixedAsset.depreciate(until: Date.new(2020, 10, 17))
      fa.reload

      _1, _2, *other = fa.depreciations
      assert_not other.any? { |d| d.accountable? }, "The remaining depreciations should not be accountable"
      assert other.all? { |d| d.journal_entry.nil? }, "The remaining depreciations should not have a journal_entry"
    end
  end
end