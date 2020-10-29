require 'test_helper'

module FixedAssetTest
  class CreationTest < Ekylibre::Testing::ApplicationTestCase

    test 'cannot create a FixedAsset when no opened FinancialYear present in database' do
      create :financial_year, state: :locked, year: 2018

      fa = build :fixed_asset,
                 started_on: Date.new(2018, 1, 5)

      assert_not fa.valid?
      assert_equal 1, fa.errors.messages.values.flatten.size, "Not expecting these error messages: #{fa.errors.messages.values.flatten.join(', ')}"

      assert fa.errors.messages.key? :base
    end

    test "can create a FixedAsset before an opened FinancialYear" do
      create :financial_year, year: 2018

      fa = build :fixed_asset,
                 started_on: Date.new(2015, 1, 2)
      assert fa.valid?, fa.errors.messages
    end
  end
end
