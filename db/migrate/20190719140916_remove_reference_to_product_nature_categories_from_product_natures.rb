class RemoveReferenceToProductNatureCategoriesFromProductNatures < ActiveRecord::Migration[4.2]
  def change
    remove_column :product_natures, :category_id
  end
end
