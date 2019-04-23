require 'test_helper'

module FixedAssetTest
  class NoneDepreciationMethodTest < Ekylibre::Testing::ApplicationTestCase
    setup do
      create :financial_year, year: 2018
    end

    test 'stopped_on, allocation_account, expenses_account are not mandatory when a FixedAsset uses the :none depreciation method' do
      fixed_asset = create :fixed_asset, :not_depreciable,
                           amount: 50_000,
                           started_on: Date.new(2018, 6, 15)

      valid = fixed_asset.valid?

      assert valid, fixed_asset.errors.messages.map { |_, v| v }.flatten
    end

    test 'a FixedAsset depreciated with :none method should not have any FixedAssetDepreciation' do
      fixed_asset = create :fixed_asset, :not_depreciable,
                           started_on: Date.new(2018, 6, 15)

      assert_equal 0, fixed_asset.depreciations.count, "Should not have a depreciation"
    end
  end
end