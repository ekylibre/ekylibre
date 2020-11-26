class ChangeCategoriesFixedAssetDepreciationMethod < ActiveRecord::Migration
  def up
    execute "UPDATE product_nature_categories SET fixed_asset_depreciation_method = 'linear' WHERE fixed_asset_depreciation_method = 'simplified_linear'"
  end

  def down
    # NOOP
  end
end
