class CreateActivityCosts < ActiveRecord::Migration[5.0]
  def change
    create_table :activity_cost_outputs do |t|
        t.references :activity, null: false, index: true, foreign_key: true
        t.references :variant, null: false, index: true
        t.references :variant_unit, null: false, index: true
        t.string :name
        t.stamps
      end
      add_foreign_key :activity_cost_outputs, :product_nature_variants, column: :variant_id
      add_foreign_key :activity_cost_outputs, :units, column: :variant_unit_id
  end
end
