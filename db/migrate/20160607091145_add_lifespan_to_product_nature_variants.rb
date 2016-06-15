class AddLifespanToProductNatureVariants < ActiveRecord::Migration
  def change
    add_column :product_nature_variants, :lifespan, :decimal, precision: 19, scale: 4
    add_column :product_nature_variants, :working_lifespan, :decimal, precision: 19, scale: 4
  end
end
