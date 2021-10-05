class UpdateCatalogItemInHour < ActiveRecord::Migration[5.0]
  EQUIPMENT_VARIETIES = %w[car tractor handling_equipment heavy_equipment motorized_vehicle portable_equipment self_propelled_equipment tank truck equipment_fleet trailed_equipment equipment].freeze

  def up
    # add hour equipment in database
    execute <<-SQL
      INSERT INTO units (name, reference_name, base_unit_id, symbol, coefficient, dimension, type, created_at, updated_at)
        VALUES
          ('Heure de travail', 'hour_worker', 15, NULL, 1.0, 'time', 'Conditioning', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
    SQL

    # update cost catalog items in hour for equipment
    execute <<-SQL
      UPDATE catalog_items SET unit_id = (SELECT min(id) FROM units where reference_name = 'hour_equipment')
        WHERE variant_id IN (
          SELECT id FROM product_nature_variants WHERE variety IN
          (#{EQUIPMENT_VARIETIES.map { |v| "'#{v}'" }.join(', ')})
        )
        AND catalog_id IN (
          SELECT id FROM catalogs WHERE usage IN
          ('travel_cost', 'cost')
        )
    SQL
    
    # update cost catalog items in hour for worker
    execute <<-SQL
      UPDATE catalog_items SET unit_id = (SELECT min(id) FROM units where reference_name = 'hour_worker')
          WHERE variant_id IN (
            SELECT id FROM product_nature_variants WHERE variety = 'worker'
          )
          AND catalog_id IN (
            SELECT id FROM catalogs WHERE usage IN
            ('travel_cost', 'cost')
          )
    SQL

    # update catalog items started_at if missing
    execute <<-SQL
      UPDATE catalog_items SET started_at = to_timestamp('01 01 2014', 'DD MM YYYY')
      WHERE started_at IS NULL
    SQL

  end

  def down
    #Nope
  end
end
