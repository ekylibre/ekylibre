class AddTypeToParcelItem < ActiveRecord::Migration
  def change
    add_column :parcel_items, :type, :string
    reversible do |dir|
      dir.up do
        execute set_parcel_items_type_to_reception_item
        execute set_parcel_items_type_to_shipment_item
      end
      dir.down do
        execute set_parcel_items_type_to_null
      end
    end
  end

  def set_parcel_items_type_to_reception_item
    <<-SQL
	    UPDATE parcel_items pi
		  SET type = 'ReceptionItem'
		  WHERE  pi.type IS NULL
	 			AND pi.parcel_id IN (
		 		SELECT parcels.id
		 		FROM parcels
		 		WHERE parcels.nature = 'incoming'
	 		)
	  SQL
  end

  def set_parcel_items_type_to_shipment_item
    <<-SQL
	    UPDATE parcel_items pi
		  SET type = 'ShipmentItem'
		  WHERE  pi.type IS NULL
	 			AND pi.parcel_id IN (
		 		SELECT parcels.id
		 		FROM parcels
		 		WHERE parcels.nature = 'outgoing'
	 		)
	  SQL
  end

  def set_parcel_items_type_to_null
    <<-SQL
	    UPDATE parcel_items pi
		  SET type = NULL
	 		)
	  SQL
  end
end
