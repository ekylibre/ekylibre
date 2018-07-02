class AddIndexesToImproveFixedAssets < ActiveRecord::Migration
  def up
    add_index :fixed_assets, :number
    add_index :fixed_asset_depreciations, :locked
    add_index :fixed_asset_depreciations, :stopped_on
    add_index :fixed_asset_depreciations, :accountable
  end

  def down
    remove_index :fixed_assets, :number
    remove_index :fixed_asset_depreciations, :locked
    remove_index :fixed_asset_depreciations, :stopped_on
    remove_index :fixed_asset_depreciations, :accountable
  end
end
