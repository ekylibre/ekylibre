class AddFranceMaaidOnVariants < ActiveRecord::Migration
  def change
    add_column :product_nature_variants, :france_maaid, :string
  end
end
