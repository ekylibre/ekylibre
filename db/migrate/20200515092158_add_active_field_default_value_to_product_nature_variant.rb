class AddActiveFieldDefaultValueToProductNatureVariant < ActiveRecord::Migration[4.2]
  def change
    change_column_default :product_nature_variants, :active, true
  end
end
