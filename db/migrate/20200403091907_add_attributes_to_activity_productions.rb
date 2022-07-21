class AddAttributesToActivityProductions < ActiveRecord::Migration[4.2]
  def change
    add_column :activity_productions, :headland_shape, :geometry, srid: 4326
  end
end
