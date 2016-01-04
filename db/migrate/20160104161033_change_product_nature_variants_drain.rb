# Migration generated with nomenclature migration #20160104160843
class ChangeProductNatureVariantsDrain < ActiveRecord::Migration
  def up
    # Change item product_nature_variants#drain with {:name=>"product_nature_variants#drain", :nature=>"draining_item"}
  end

  def down
    # Reverse: Change item product_nature_variants#drain with {:name=>"product_nature_variants#drain", :nature=>"draining_item"}
  end
end
