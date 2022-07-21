class AddDefaultUnitToExistingPrices < ActiveRecord::Migration[4.2]
  def change
    reversible do |dir|

      dir.up do
        # Set hour unit in Worker and Equipment prices from cost catalog.
        execute <<-SQL
          UPDATE catalog_items AS ci
            SET unit_id = (SELECT min(id) FROM units WHERE reference_name = 'hour_equipment')
          FROM product_nature_variants AS pnv
          WHERE ci.variant_id = pnv.id
            AND pnv.type IN ('Variants::WorkerVariant', 'Variants::EquipmentVariant')
            AND ci.catalog_id IN (SELECT id FROM catalogs WHERE usage IN ('travel_cost', 'cost'));
        SQL

      end

      dir.down do
        # NOPE
      end

    end
  end
end
