class CreateProductNatureVariantSuppliersInfos < ActiveRecord::Migration[5.0]
  def change
    create_view :product_nature_variant_suppliers_infos
  end
end
