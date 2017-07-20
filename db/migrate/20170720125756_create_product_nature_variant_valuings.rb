class CreateProductNatureVariantValuings < ActiveRecord::Migration
  def change
    create_table :product_nature_variant_valuings do |t|
      t.decimal :average_cost_amount, precision: 19, scale: 4, null: false
      t.decimal :amount, precision: 19, scale: 4,              null: false
      t.references :variant,                                   null: false, index: true
      t.timestamps                                             null: false
    end
  end
end
