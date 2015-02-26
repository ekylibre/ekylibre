class AddCrumbs < ActiveRecord::Migration
  def change

    create_table :crumbs do |t|
      t.references :user,        null: false, index: true
      t.st_point   :geolocation, null: false, srid: 4326
      t.datetime   :read_at,     null: false
      t.decimal    :accuracy,    null: false
      t.string     :nature,      null: false
      t.text       :metadata
      t.stamps
      t.index      :nature
      t.index      :read_at
    end

  end
end
