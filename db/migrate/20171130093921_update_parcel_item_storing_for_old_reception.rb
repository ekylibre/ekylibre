class UpdateParcelItemStoringForOldReception < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute update_storing
        execute create_parcel_item_storings
      end

      dir.down do
        execute remove_product_id
      end
    end
  end

  def update_storing
    <<-SQL
      UPDATE parcel_item_storings AS pis
      -- INNER JOIN parcel_items AS parcel_item ON pis.parcel_item_id = parcel_item.id
      SET product_id = parcel_item.product_id
      FROM parcel_items AS parcel_item
      WHERE pis.product_id IS NULL
        AND pis.parcel_item_id = parcel_item.id
        AND parcel_item.type = 'ReceptionItem'
    SQL
  end

  def create_parcel_item_storings
    <<-SQL
      INSERT INTO parcel_item_storings (product_id, parcel_item_id, quantity, storage_id, created_at, updated_at)
      SELECT parcel_item.product_id, parcel_item.id, parcel_item.population, parcel.storage_id, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM parcel_items AS parcel_item
      INNER JOIN parcels AS parcel ON parcel_item.parcel_id = parcel.id
      INNER JOIN products AS product ON parcel_item.product_id = product.id
      WHERE parcel_item.id NOT IN (SELECT id FROM parcel_item_storings)
        AND parcel_item.type = 'ReceptionItem'
        AND parcel.storage_id IS NOT NULL
        AND parcel_item.product_id IS NOT NULL
    SQL
  end

  def remove_product_id
    <<-SQL
      UPDATE parcel_item_storings AS pis
      SET product_id = NULL
      WHERE pis.product_id IS NOT NULL
      SQL
  end
end
