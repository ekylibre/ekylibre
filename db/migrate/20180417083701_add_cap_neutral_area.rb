class AddCapNeutralArea < ActiveRecord::Migration
  def change
    create_table :cap_neutral_areas do |t|
      t.references :cap_statement, index: true, null: false, foreign_key: true
      t.string :number, null: false
      t.string :category, null: false
      t.string :nature, null: false
      t.geometry :shape, null: false, srid: 4326
      t.stamps
    end
  end
end
