class AddSiretAndShapeSupports < ActiveRecord::Migration
  def change
    rename_column :entities, :siren, :siret

    add_column :production_supports, :shape, :geometry, srid: 4326
  end
end
