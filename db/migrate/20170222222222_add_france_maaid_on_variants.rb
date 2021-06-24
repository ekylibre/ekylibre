class AddFranceMaaidOnVariants < ActiveRecord::Migration[4.2]
  def change
    add_column :product_nature_variants, :france_maaid, :string
  end
end
