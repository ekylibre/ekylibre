class UpdateRoleOfServiceReceptionItem < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute set_parcel_item_role_to_service
      end

      dir.down do
        execute set_parcel_item_role_to_null
      end
    end
  end

  def set_parcel_item_role_to_service
    <<-SQL
      UPDATE parcel_items pi
      SET role = 'service'
      FROM parcel_items as parcel_item
      INNER JOIN parcels AS parcel ON parcel_item.parcel_id = parcel.id
      WHERE pi.role IS NULL
        AND pi.type = 'ReceptionItem'
        AND parcel.intervention_id IS NOT NULL
    SQL
  end

  def set_parcel_item_role_to_null
    <<-SQL
      UPDATE parcel_items pi
      SET role = NULL
      FROM parcel_items as parcel_item
      INNER JOIN parcels AS parcel ON parcel_item.parcel_id = parcel.id
      WHERE pi.type = 'ReceptionItem'
        AND parcel.intervention_id IS NOT NULL
    SQL
  end
end
