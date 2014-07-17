class AddCrumbs < ActiveRecord::Migration
  def change
    # id INTEGER PRIMARY KEY AUTOINCREMENT, name VARCHAR, latitude FLOAT, longitude FLOAT, read_at DATE, accuracy FLOAT, type TEXT, code TEXT, quantity NUMERIC, unit TEXT)
    create_table :crumbs do |t|
      t.references :user,        null: false
      t.point      :geolocation, null: false, srid: 4326
      t.datetime   :read_at,     null: false
      t.decimal    :accuracy,    null: false
      t.string     :nature,      null: false
      t.text       :metadata
      t.stamps
    end

  end
end
