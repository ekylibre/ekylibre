class AddGeocoderAttributes < ActiveRecord::Migration[4.2]
  def change
    add_column :entity_addresses, :latitude, :decimal, precision: 19, scale: 15
    add_column :entity_addresses, :longitude, :decimal, precision: 19, scale: 15
  end
end
