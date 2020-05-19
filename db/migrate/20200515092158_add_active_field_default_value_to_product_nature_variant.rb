class AddActiveFieldDefaultValueToProductNatureVariant < ActiveRecord::Migration
  def change
    change_column_default :product_nature_variants, :active, true
  end
end
