class AddProductNatureCategoryReferenceToInventory < ActiveRecord::Migration[4.2]
  def change
    add_reference :inventories, :product_nature_category, index: true, foreign_key: true
  end
end
