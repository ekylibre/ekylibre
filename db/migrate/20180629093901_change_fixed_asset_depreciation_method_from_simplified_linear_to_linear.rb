class ChangeFixedAssetDepreciationMethodFromSimplifiedLinearToLinear < ActiveRecord::Migration[4.2]
  def up
    execute "UPDATE fixed_assets SET depreciation_method = 'linear' WHERE depreciation_method = 'simplified_linear'"
  end

  def down
    # No reversible code
  end
end
