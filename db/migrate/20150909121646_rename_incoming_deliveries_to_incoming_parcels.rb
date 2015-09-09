class RenameIncomingDeliveriesToIncomingParcels < ActiveRecord::Migration
  def change
    rename_table :incoming_deliveries, :incoming_parcels
    # Polymorphic columns
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:affairs)} SET #{quote_column_name(:type)}='IncomingParcel' WHERE #{quote_column_name(:type)}='IncomingDelivery'"
        execute "UPDATE #{quote_table_name(:attachments)} SET #{quote_column_name(:resource_type)}='IncomingParcel' WHERE #{quote_column_name(:resource_type)}='IncomingDelivery'"
        execute "UPDATE #{quote_table_name(:issues)} SET #{quote_column_name(:target_type)}='IncomingParcel' WHERE #{quote_column_name(:target_type)}='IncomingDelivery'"
        execute "UPDATE #{quote_table_name(:journal_entries)} SET #{quote_column_name(:resource_type)}='IncomingParcel' WHERE #{quote_column_name(:resource_type)}='IncomingDelivery'"
        execute "UPDATE #{quote_table_name(:observations)} SET #{quote_column_name(:subject_type)}='IncomingParcel' WHERE #{quote_column_name(:subject_type)}='IncomingDelivery'"
        execute "UPDATE #{quote_table_name(:preferences)} SET #{quote_column_name(:record_value_type)}='IncomingParcel' WHERE #{quote_column_name(:record_value_type)}='IncomingDelivery'"
        execute "UPDATE #{quote_table_name(:product_enjoyments)} SET #{quote_column_name(:originator_type)}='IncomingParcel' WHERE #{quote_column_name(:originator_type)}='IncomingDelivery'"
        execute "UPDATE #{quote_table_name(:product_junctions)} SET #{quote_column_name(:originator_type)}='IncomingParcel' WHERE #{quote_column_name(:originator_type)}='IncomingDelivery'"
        execute "UPDATE #{quote_table_name(:product_linkages)} SET #{quote_column_name(:originator_type)}='IncomingParcel' WHERE #{quote_column_name(:originator_type)}='IncomingDelivery'"
        execute "UPDATE #{quote_table_name(:product_links)} SET #{quote_column_name(:originator_type)}='IncomingParcel' WHERE #{quote_column_name(:originator_type)}='IncomingDelivery'"
        execute "UPDATE #{quote_table_name(:product_localizations)} SET #{quote_column_name(:originator_type)}='IncomingParcel' WHERE #{quote_column_name(:originator_type)}='IncomingDelivery'"
        execute "UPDATE #{quote_table_name(:product_memberships)} SET #{quote_column_name(:originator_type)}='IncomingParcel' WHERE #{quote_column_name(:originator_type)}='IncomingDelivery'"
        execute "UPDATE #{quote_table_name(:product_ownerships)} SET #{quote_column_name(:originator_type)}='IncomingParcel' WHERE #{quote_column_name(:originator_type)}='IncomingDelivery'"
        execute "UPDATE #{quote_table_name(:product_phases)} SET #{quote_column_name(:originator_type)}='IncomingParcel' WHERE #{quote_column_name(:originator_type)}='IncomingDelivery'"
        execute "UPDATE #{quote_table_name(:product_reading_tasks)} SET #{quote_column_name(:originator_type)}='IncomingParcel' WHERE #{quote_column_name(:originator_type)}='IncomingDelivery'"
        execute "UPDATE #{quote_table_name(:product_readings)} SET #{quote_column_name(:originator_type)}='IncomingParcel' WHERE #{quote_column_name(:originator_type)}='IncomingDelivery'"
        execute "UPDATE #{quote_table_name(:products)} SET #{quote_column_name(:type)}='IncomingParcel' WHERE #{quote_column_name(:type)}='IncomingDelivery'"
        execute "UPDATE #{quote_table_name(:versions)} SET #{quote_column_name(:item_type)}='IncomingParcel' WHERE #{quote_column_name(:item_type)}='IncomingDelivery'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:affairs)} SET #{quote_column_name(:type)}='IncomingDelivery' WHERE #{quote_column_name(:type)}='IncomingParcel'"
        execute "UPDATE #{quote_table_name(:attachments)} SET #{quote_column_name(:resource_type)}='IncomingDelivery' WHERE #{quote_column_name(:resource_type)}='IncomingParcel'"
        execute "UPDATE #{quote_table_name(:issues)} SET #{quote_column_name(:target_type)}='IncomingDelivery' WHERE #{quote_column_name(:target_type)}='IncomingParcel'"
        execute "UPDATE #{quote_table_name(:journal_entries)} SET #{quote_column_name(:resource_type)}='IncomingDelivery' WHERE #{quote_column_name(:resource_type)}='IncomingParcel'"
        execute "UPDATE #{quote_table_name(:observations)} SET #{quote_column_name(:subject_type)}='IncomingDelivery' WHERE #{quote_column_name(:subject_type)}='IncomingParcel'"
        execute "UPDATE #{quote_table_name(:preferences)} SET #{quote_column_name(:record_value_type)}='IncomingDelivery' WHERE #{quote_column_name(:record_value_type)}='IncomingParcel'"
        execute "UPDATE #{quote_table_name(:product_enjoyments)} SET #{quote_column_name(:originator_type)}='IncomingDelivery' WHERE #{quote_column_name(:originator_type)}='IncomingParcel'"
        execute "UPDATE #{quote_table_name(:product_junctions)} SET #{quote_column_name(:originator_type)}='IncomingDelivery' WHERE #{quote_column_name(:originator_type)}='IncomingParcel'"
        execute "UPDATE #{quote_table_name(:product_linkages)} SET #{quote_column_name(:originator_type)}='IncomingDelivery' WHERE #{quote_column_name(:originator_type)}='IncomingParcel'"
        execute "UPDATE #{quote_table_name(:product_links)} SET #{quote_column_name(:originator_type)}='IncomingDelivery' WHERE #{quote_column_name(:originator_type)}='IncomingParcel'"
        execute "UPDATE #{quote_table_name(:product_localizations)} SET #{quote_column_name(:originator_type)}='IncomingDelivery' WHERE #{quote_column_name(:originator_type)}='IncomingParcel'"
        execute "UPDATE #{quote_table_name(:product_memberships)} SET #{quote_column_name(:originator_type)}='IncomingDelivery' WHERE #{quote_column_name(:originator_type)}='IncomingParcel'"
        execute "UPDATE #{quote_table_name(:product_ownerships)} SET #{quote_column_name(:originator_type)}='IncomingDelivery' WHERE #{quote_column_name(:originator_type)}='IncomingParcel'"
        execute "UPDATE #{quote_table_name(:product_phases)} SET #{quote_column_name(:originator_type)}='IncomingDelivery' WHERE #{quote_column_name(:originator_type)}='IncomingParcel'"
        execute "UPDATE #{quote_table_name(:product_reading_tasks)} SET #{quote_column_name(:originator_type)}='IncomingDelivery' WHERE #{quote_column_name(:originator_type)}='IncomingParcel'"
        execute "UPDATE #{quote_table_name(:product_readings)} SET #{quote_column_name(:originator_type)}='IncomingDelivery' WHERE #{quote_column_name(:originator_type)}='IncomingParcel'"
        execute "UPDATE #{quote_table_name(:products)} SET #{quote_column_name(:type)}='IncomingDelivery' WHERE #{quote_column_name(:type)}='IncomingParcel'"
        execute "UPDATE #{quote_table_name(:versions)} SET #{quote_column_name(:item_type)}='IncomingDelivery' WHERE #{quote_column_name(:item_type)}='IncomingParcel'"
      end
    end
    # Custom fields
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:custom_fields)} SET #{quote_column_name(:customized_type)}='IncomingParcel' WHERE #{quote_column_name(:customized_type)}='IncomingDelivery'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:custom_fields)} SET #{quote_column_name(:customized_type)}='IncomingDelivery' WHERE #{quote_column_name(:customized_type)}='IncomingParcel'"
      end
    end
    # Listings
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:listings)} SET #{quote_column_name(:root_model)}='incoming_parcel' WHERE #{quote_column_name(:root_model)}='incoming_delivery'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:listings)} SET #{quote_column_name(:root_model)}='incoming_delivery' WHERE #{quote_column_name(:root_model)}='incoming_parcel'"
      end
    end
    # Sequences
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:sequences)} SET #{quote_column_name(:usage)}='incoming_parcels' WHERE #{quote_column_name(:usage)}='incoming_deliveries'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:sequences)} SET #{quote_column_name(:usage)}='incoming_deliveries' WHERE #{quote_column_name(:usage)}='incoming_parcels'"
      end
    end

    rename_column :incoming_parcel_items, :delivery_id, :parcel_id
  end
end
