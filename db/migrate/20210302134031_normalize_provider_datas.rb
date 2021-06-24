class NormalizeProviderDatas < ActiveRecord::Migration[5.0]
  def up
    # update products provider column
    execute <<~SQL
      WITH products2 AS (
        SELECT products.id, products.provider, cvi_cultivable_zones.cvi_statement_id AS cvi_statement_id
        FROM  products
        LEFT JOIN cvi_land_parcels ON (provider ->> 'cvi_land_parcel_id')::integer = cvi_land_parcels.id
        LEFT JOIN cvi_cultivable_zones ON cvi_land_parcels.cvi_cultivable_zone_id = cvi_cultivable_zones.id
      )
      UPDATE products products1
      SET provider = json_build_object(
        'vendor', 'ekylibre',
        'name', 'cvi_statement',
        'id', products2.cvi_statement_id,
        'data', json_build_object(
          'cvi_land_parcel_id', (products2.provider ->> 'cvi_land_parcel_id')::integer
          )
      )
      FROM products2
      WHERE products2.id = products1.id AND products2.provider ? 'cvi_land_parcel_id'
    SQL

    # update activity_production provider column
    execute <<~SQL
      WITH activity_productions2 AS (
        SELECT activity_productions.id, activity_productions.provider, cvi_cultivable_zones.cvi_statement_id AS cvi_statement_id
        FROM  activity_productions
        LEFT JOIN cvi_land_parcels ON (provider ->> 'cvi_land_parcel_id')::integer = cvi_land_parcels.id
        LEFT JOIN cvi_cultivable_zones ON cvi_land_parcels.cvi_cultivable_zone_id = cvi_cultivable_zones.id
      )
      UPDATE activity_productions activity_productions1
      SET provider = json_build_object(
        'vendor', 'ekylibre',
        'name', 'cvi_statement',
        'id', activity_productions2.cvi_statement_id,
        'data', json_build_object(
          'cvi_land_parcel_id', (activity_productions2.provider ->> 'cvi_land_parcel_id')::integer
          )
      )
      FROM activity_productions2
      WHERE activity_productions2.id = activity_productions1.id AND activity_productions2.provider ? 'cvi_land_parcel_id'
    SQL
  end
end
