class UpdateProductsActivityProductionForeignKey < ActiveRecord::Migration
  def change
    remove_foreign_key :products, :activity_productions
    add_foreign_key :products, :activity_productions, on_delete: :cascade
  end
end
