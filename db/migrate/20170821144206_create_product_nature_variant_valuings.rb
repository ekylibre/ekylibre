class CreateProductNatureVariantValuings < ActiveRecord::Migration
  def change
    create_table :product_nature_variant_valuings do |t|
      t.decimal :average_cost_amount, precision: 19, scale: 4, null: false
      t.decimal :amount, precision: 19, scale: 4,              null: false
      t.integer :variant_id,                                   null: false
      t.datetime :computed_at,                                 null: false
      t.stamps                                             null: false
    end
    add_foreign_key :product_nature_variant_valuings, :product_nature_variants, column: :variant_id, index: true, foreign_key: true
    add_column :product_nature_variants, :valuing_id, :integer
    add_foreign_key :product_nature_variants, :product_nature_variant_valuings, column: :valuing_id, index: true, foreign_key: true
  end
end
