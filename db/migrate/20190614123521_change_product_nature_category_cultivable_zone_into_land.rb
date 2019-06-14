# Migration generated with nomenclature migration #20190326135443
class ChangeProductNatureCategoryCultivableZoneIntoLand < ActiveRecord::Migration
  def up
    # Change item product_nature_categories#cultivable_zone with {:name=>"land", :pictogram=>"land_parcels", :purchasable=>"true", :saleable=>"true", :asset_fixable=>"true", :depreciable=>"false", :charge_account=>"land_charges", :product_account=>"land_sales", :fixed_asset_account=>"land_tangible_fixed_assets"}
  end

  def down
    # Reverse: Change item product_nature_categories#cultivable_zone with {:name=>"land", :pictogram=>"land_parcels", :purchasable=>"true", :saleable=>"true", :asset_fixable=>"true", :depreciable=>"false", :charge_account=>"land_charges", :product_account=>"land_sales", :fixed_asset_account=>"land_tangible_fixed_assets"}
  end
end
