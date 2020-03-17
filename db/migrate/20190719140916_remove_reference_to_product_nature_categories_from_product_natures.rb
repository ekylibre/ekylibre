class RemoveReferenceToProductNatureCategoriesFromProductNatures < ActiveRecord::Migration
  def change
    remove_column :product_natures, :category_id
  end
end
