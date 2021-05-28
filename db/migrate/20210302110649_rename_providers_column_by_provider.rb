class RenameProvidersColumnByProvider < ActiveRecord::Migration[5.0]
  def up
    rename_column :activity_productions, :providers, :provider

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

    remove_column :products, :providers
  end

  def down
    add_column :products, :providers, :jsonb, default: {}
    execute <<~SQL
      UPDATE products SET providers = provider
      WHERE provider::text <> '{}'::text
        AND providers::text = '{}'::text;
    SQL

    rename_column :activity_productions, :provider, :providers
  end
end
