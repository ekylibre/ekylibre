class CreateLabels < ActiveRecord::Migration
  def change
    create_table :labels do |t|
      t.string :name, null: false
      t.string :color, null: false
      t.stamps
      t.index :name, unique: true
    end

    create_table :intervention_labellings do |t|
      t.references :intervention, null: false, index: true
      t.references :label, null: false, index: true
      t.stamps
      t.index %i[intervention_id label_id], unique: true
    end

    create_table :product_labellings do |t|
      t.references :product, null: false, index: true
      t.references :label, null: false, index: true
      t.stamps
      t.index %i[product_id label_id], unique: true
    end
  end
end
