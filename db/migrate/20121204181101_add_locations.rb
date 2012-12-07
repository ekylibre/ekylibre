class AddLocations < ActiveRecord::Migration
  def change
    create_table :locations do |t|
      t.string :name
      t.point :latlon, :geographic => true
      t.stamps
    end
  end
end
