class CreateProductPopulations < ActiveRecord::Migration
  def change
    create_table :product_populations do |t|
      t.references :product, index: true, foreign_key: true
      t.decimal :value, precision: 19, scale: 4

      t.datetime :started_at, null: false
      t.datetime :stopped_at

      t.stamps

      t.index :started_at
      t.index :stopped_at
      t.index [:product_id, :started_at], unique: true
    end
  end
end
