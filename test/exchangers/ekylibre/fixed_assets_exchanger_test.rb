require 'test_helper'

module Ekylibre
  class FixedAssetsExchangerTest < ActiveExchanger::TestCase

    setup do
      # We want to keep tracking of import resource
      ::I18n.locale = :fra
      @import = Import.create!(nature: :ekylibre_fixed_assets, creator: User.first)
      @second_import = Import.create!(nature: :ekylibre_fixed_assets, creator: User.first)
    end

    test 'import' do
      result = Ekylibre::FixedAssetsExchanger.build(fixture_files_path.join('imports', 'ekylibre', 'fixed_assets.csv'), options: { import_id: @import.id }).run
      assert result.success?, [result.message, result.exception]
      fa_count = FixedAsset.all.count
      assert_equal true, fa_count > 1
      second_result = Ekylibre::FixedAssetsExchanger.build(fixture_files_path.join('imports', 'ekylibre', 'fixed_assets.csv'), options: { import_id: @second_import.id }).run
      assert second_result.success?, [second_result.message, second_result.exception]
      second_fa_count = FixedAsset.all.count
      # check not double object on the same fixed asset by the same provider
      assert_equal true, fa_count == second_fa_count
    end
  end
end
