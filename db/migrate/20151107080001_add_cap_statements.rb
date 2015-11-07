class AddCapStatements < ActiveRecord::Migration
  def change

    #cap_statements
    create_table :cap_statements do |t|
      t.references :campaign, null: false, index: true
      t.references :entity, index: true
      t.string :pacage_number,       null: false
      t.string :siret_number,        null: false
      t.string :exploitation_name,   null: false
      t.stamps
    end

    #cap_islets
    create_table :cap_islets do |t|
      t.references :cap_statement, null: false, index: true
      t.string :islet_number,       null: false
      t.string :town_number,        null: false
      t.geometry :shape, null: false, srid: 4326
      t.stamps
    end

    #cap_land_parcels
    create_table :cap_land_parcels do |t|
      t.references :cap_islet, null: false, index: true
      t.references :support, index: true
      t.string :land_parcel_number,       null: false
      t.string :main_crop_code,           null: false
      t.string :main_crop_precision
      t.boolean :main_crop_seed_production, default: false, null: false
      t.boolean :main_crop_commercialisation, default: false, null: false
      t.geometry :shape, null: false, srid: 4326
      t.stamps
    end

  end
end
