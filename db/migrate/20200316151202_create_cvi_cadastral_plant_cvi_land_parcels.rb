class CreateCviCadastralPlantCviLandParcels < ActiveRecord::Migration
  def change
    create_table :cvi_cadastral_plant_cvi_land_parcels do |t|
      t.decimal :percentage, default: 1.0
      t.references :cvi_land_parcel, index: { name: :index_on_cvi_land_parcel_id }, foreign_key: true
      t.references :cvi_cadastral_plant, index: { name: :index_on_cvi_cadastral_plant_id }, foreign_key: true

      t.timestamps null: false
    end
  end
end
