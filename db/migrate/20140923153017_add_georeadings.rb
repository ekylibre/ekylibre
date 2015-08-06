class AddGeoreadings < ActiveRecord::Migration
  def change
    create_table :georeadings do |t|
      t.string :name,                    null: false
      t.string :nature,                  null: false
      t.string :number
      t.text :description
      t.geometry :content, srid: 4326, null: false
      t.stamps
      t.index :name
      t.index :number
      t.index :nature
    end
  end
end
