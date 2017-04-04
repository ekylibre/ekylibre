class AddCapStatements < ActiveRecord::Migration
  def change
    # cap_statements
    create_table :cap_statements do |t|
      t.references :campaign, null: false, index: true
      t.references :declarant, index: true
      t.string :pacage_number
      t.string :siret_number
      t.string :farm_name
      t.stamps
    end

    # cap_islets
    create_table :cap_islets do |t|
      t.references :cap_statement, null: false, index: true
      t.string :islet_number, null: false
      t.string :town_number
      t.geometry :shape, null: false, srid: 4326
      t.stamps
    end

    # cap_land_parcels
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

    count = select_value('SELECT count(*) FROM products WHERE type = \'LandParcelCluster\'').to_i
    if count > 0
      company = select_one('SELECT * FROM entities ORDER BY of_company DESC').symbolize_keys
      count = select_value('SELECT count(*) FROM campaigns').to_i
      unless count > 0
        year = Time.zone.now.year
        execute "INSERT INTO campaigns(name, number, harvest_year, created_at, updated_at) VALUES ('#{year}', '#{year}', #{year}, current_timestamp, current_timestamp)"
      end
      campaign = select_one('SELECT * FROM campaigns ORDER BY id DESC').symbolize_keys
      execute "INSERT INTO cap_statements (campaign_id, declarant_id, siret_number, farm_name, created_at, creator_id, updated_at, updater_id) SELECT id, #{company[:id]}, #{quote(company[:siren])}, #{quote(company[:full_name])}, created_at, creator_id, updated_at, updater_id FROM campaigns WHERE id = #{campaign[:id]}"
      execute "INSERT INTO cap_islets (cap_statement_id, islet_number, shape, created_at, creator_id, updated_at, updater_id, lock_version) SELECT cs.id, lpc.number, lpc.initial_shape, lpc.created_at, lpc.creator_id, lpc.updated_at, lpc.updater_id, lpc.lock_version  FROM cap_statements AS cs, products AS lpc WHERE lpc.type = 'LandParcelCluster' AND initial_shape IS NOT NULL"
      execute "INSERT INTO cap_land_parcels (cap_islet_id, land_parcel_number, main_crop_code, shape, created_at, creator_id, updated_at, updater_id, lock_version) SELECT ci.id, lp.number, '???', lp.initial_shape, lp.created_at, lp.creator_id, lp.updated_at, lp.updater_id, lp.lock_version FROM products AS lp JOIN cap_islets AS ci ON (ST_Covers(ST_CollectionExtract(ci.shape, 3), ST_CollectionExtract(lp.initial_shape, 3))) WHERE lp.type = 'LandParcel' AND initial_shape IS NOT NULL"
    end

    drop_table :cultivable_zone_memberships

    %i[product_enjoyments product_ownerships product_junction_ways product_phases product_localizations product_readings].each do |table|
      execute "DELETE FROM #{table} WHERE product_id IN (SELECT id FROM products WHERE type in ('LandParcelGroup', 'LandParcelCluster', 'LandParcel'))"
    end

    execute 'DELETE FROM product_junctions WHERE id NOT IN (SELECT junction_id FROM product_junction_ways)'

    execute "DELETE FROM product_memberships WHERE group_id IN (SELECT id FROM products WHERE type in ('LandParcelGroup', 'LandParcelCluster', 'LandParcel')) OR member_id IN (SELECT id FROM products WHERE type in ('LandParcelGroup', 'LandParcelCluster', 'LandParcel'))"

    execute "DELETE FROM product_links WHERE product_id IN (SELECT id FROM products WHERE type in ('LandParcelGroup', 'LandParcelCluster', 'LandParcel')) OR linked_id IN (SELECT id FROM products WHERE type in ('LandParcelGroup', 'LandParcelCluster', 'LandParcel'))"

    execute "DELETE FROM product_linkages WHERE carrier_id IN (SELECT id FROM products WHERE type in ('LandParcelGroup', 'LandParcelCluster', 'LandParcel')) OR carried_id IN (SELECT id FROM products WHERE type in ('LandParcelGroup', 'LandParcelCluster', 'LandParcel'))"

    %i[users roles].each do |table|
      execute "UPDATE #{table} SET rights = REPLACE(rights, 'land_parcel_clusters', 'cap_statements')"
    end

    execute "DELETE FROM products WHERE type in ('LandParcelGroup', 'LandParcelCluster', 'LandParcel')"
  end
end
