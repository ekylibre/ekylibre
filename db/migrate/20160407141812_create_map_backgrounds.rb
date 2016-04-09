class CreateMapBackgrounds < ActiveRecord::Migration
  def change
    create_table :map_backgrounds do |t|
      t.string :name, null: false, index: true
      t.string :url, null: false
      t.string :base_layer
      t.string :base_variant
      t.boolean :enabled, default: false, null: false
      t.boolean :by_default, default: false, null: false

      t.stamps
    end
  end
end
