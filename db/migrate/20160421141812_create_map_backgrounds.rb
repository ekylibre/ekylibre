class CreateMapBackgrounds < ActiveRecord::Migration
  def change
    create_table :map_backgrounds do |t|
      t.string :name, null: false, index: true
      t.string :url, null: false
      t.string :reference_name, null: true
      t.string :attribution, null: true
      t.string :subdomains, null: true
      t.integer :min_zoom, null: true
      t.integer :max_zoom, null: true
      t.boolean :managed, default: false, null: false
      t.boolean :tms, default: false, null: false
      t.boolean :enabled, default: false, null: false
      t.boolean :by_default, default: false, null: false

      t.stamps
    end
  end
end
