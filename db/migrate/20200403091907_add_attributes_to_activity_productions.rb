class AddAttributesToActivityProductions < ActiveRecord::Migration
  def change
    add_column :activity_productions, :headland_shape, :geometry, srid: 4326
  end
end
