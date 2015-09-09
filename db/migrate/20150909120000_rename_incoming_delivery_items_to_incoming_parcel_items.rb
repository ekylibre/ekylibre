class RenameIncomingDeliveryItemsToIncomingParcelItems < ActiveRecord::Migration
  def change
    rename_table :incoming_delivery_items, :incoming_parcel_items
    # Polymorphic columns
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:affairs)} SET #{quote_column_name(:type)}='IncomingParcelItem' WHERE #{quote_column_name(:type)}='IncomingDeliveryItem'"
        execute "UPDATE #{quote_table_name(:attachments)} SET #{quote_column_name(:resource_type)}='IncomingParcelItem' WHERE #{quote_column_name(:resource_type)}='IncomingDeliveryItem'"
        execute "UPDATE #{quote_table_name(:issues)} SET #{quote_column_name(:target_type)}='IncomingParcelItem' WHERE #{quote_column_name(:target_type)}='IncomingDeliveryItem'"
        execute "UPDATE #{quote_table_name(:journal_entries)} SET #{quote_column_name(:resource_type)}='IncomingParcelItem' WHERE #{quote_column_name(:resource_type)}='IncomingDeliveryItem'"
        execute "UPDATE #{quote_table_name(:observations)} SET #{quote_column_name(:subject_type)}='IncomingParcelItem' WHERE #{quote_column_name(:subject_type)}='IncomingDeliveryItem'"
        execute "UPDATE #{quote_table_name(:preferences)} SET #{quote_column_name(:record_value_type)}='IncomingParcelItem' WHERE #{quote_column_name(:record_value_type)}='IncomingDeliveryItem'"
        execute "UPDATE #{quote_table_name(:product_enjoyments)} SET #{quote_column_name(:originator_type)}='IncomingParcelItem' WHERE #{quote_column_name(:originator_type)}='IncomingDeliveryItem'"
        execute "UPDATE #{quote_table_name(:product_junctions)} SET #{quote_column_name(:originator_type)}='IncomingParcelItem' WHERE #{quote_column_name(:originator_type)}='IncomingDeliveryItem'"
        execute "UPDATE #{quote_table_name(:product_linkages)} SET #{quote_column_name(:originator_type)}='IncomingParcelItem' WHERE #{quote_column_name(:originator_type)}='IncomingDeliveryItem'"
        execute "UPDATE #{quote_table_name(:product_links)} SET #{quote_column_name(:originator_type)}='IncomingParcelItem' WHERE #{quote_column_name(:originator_type)}='IncomingDeliveryItem'"
        execute "UPDATE #{quote_table_name(:product_localizations)} SET #{quote_column_name(:originator_type)}='IncomingParcelItem' WHERE #{quote_column_name(:originator_type)}='IncomingDeliveryItem'"
        execute "UPDATE #{quote_table_name(:product_memberships)} SET #{quote_column_name(:originator_type)}='IncomingParcelItem' WHERE #{quote_column_name(:originator_type)}='IncomingDeliveryItem'"
        execute "UPDATE #{quote_table_name(:product_ownerships)} SET #{quote_column_name(:originator_type)}='IncomingParcelItem' WHERE #{quote_column_name(:originator_type)}='IncomingDeliveryItem'"
        execute "UPDATE #{quote_table_name(:product_phases)} SET #{quote_column_name(:originator_type)}='IncomingParcelItem' WHERE #{quote_column_name(:originator_type)}='IncomingDeliveryItem'"
        execute "UPDATE #{quote_table_name(:product_reading_tasks)} SET #{quote_column_name(:originator_type)}='IncomingParcelItem' WHERE #{quote_column_name(:originator_type)}='IncomingDeliveryItem'"
        execute "UPDATE #{quote_table_name(:product_readings)} SET #{quote_column_name(:originator_type)}='IncomingParcelItem' WHERE #{quote_column_name(:originator_type)}='IncomingDeliveryItem'"
        execute "UPDATE #{quote_table_name(:products)} SET #{quote_column_name(:type)}='IncomingParcelItem' WHERE #{quote_column_name(:type)}='IncomingDeliveryItem'"
        execute "UPDATE #{quote_table_name(:versions)} SET #{quote_column_name(:item_type)}='IncomingParcelItem' WHERE #{quote_column_name(:item_type)}='IncomingDeliveryItem'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:affairs)} SET #{quote_column_name(:type)}='IncomingDeliveryItem' WHERE #{quote_column_name(:type)}='IncomingParcelItem'"
        execute "UPDATE #{quote_table_name(:attachments)} SET #{quote_column_name(:resource_type)}='IncomingDeliveryItem' WHERE #{quote_column_name(:resource_type)}='IncomingParcelItem'"
        execute "UPDATE #{quote_table_name(:issues)} SET #{quote_column_name(:target_type)}='IncomingDeliveryItem' WHERE #{quote_column_name(:target_type)}='IncomingParcelItem'"
        execute "UPDATE #{quote_table_name(:journal_entries)} SET #{quote_column_name(:resource_type)}='IncomingDeliveryItem' WHERE #{quote_column_name(:resource_type)}='IncomingParcelItem'"
        execute "UPDATE #{quote_table_name(:observations)} SET #{quote_column_name(:subject_type)}='IncomingDeliveryItem' WHERE #{quote_column_name(:subject_type)}='IncomingParcelItem'"
        execute "UPDATE #{quote_table_name(:preferences)} SET #{quote_column_name(:record_value_type)}='IncomingDeliveryItem' WHERE #{quote_column_name(:record_value_type)}='IncomingParcelItem'"
        execute "UPDATE #{quote_table_name(:product_enjoyments)} SET #{quote_column_name(:originator_type)}='IncomingDeliveryItem' WHERE #{quote_column_name(:originator_type)}='IncomingParcelItem'"
        execute "UPDATE #{quote_table_name(:product_junctions)} SET #{quote_column_name(:originator_type)}='IncomingDeliveryItem' WHERE #{quote_column_name(:originator_type)}='IncomingParcelItem'"
        execute "UPDATE #{quote_table_name(:product_linkages)} SET #{quote_column_name(:originator_type)}='IncomingDeliveryItem' WHERE #{quote_column_name(:originator_type)}='IncomingParcelItem'"
        execute "UPDATE #{quote_table_name(:product_links)} SET #{quote_column_name(:originator_type)}='IncomingDeliveryItem' WHERE #{quote_column_name(:originator_type)}='IncomingParcelItem'"
        execute "UPDATE #{quote_table_name(:product_localizations)} SET #{quote_column_name(:originator_type)}='IncomingDeliveryItem' WHERE #{quote_column_name(:originator_type)}='IncomingParcelItem'"
        execute "UPDATE #{quote_table_name(:product_memberships)} SET #{quote_column_name(:originator_type)}='IncomingDeliveryItem' WHERE #{quote_column_name(:originator_type)}='IncomingParcelItem'"
        execute "UPDATE #{quote_table_name(:product_ownerships)} SET #{quote_column_name(:originator_type)}='IncomingDeliveryItem' WHERE #{quote_column_name(:originator_type)}='IncomingParcelItem'"
        execute "UPDATE #{quote_table_name(:product_phases)} SET #{quote_column_name(:originator_type)}='IncomingDeliveryItem' WHERE #{quote_column_name(:originator_type)}='IncomingParcelItem'"
        execute "UPDATE #{quote_table_name(:product_reading_tasks)} SET #{quote_column_name(:originator_type)}='IncomingDeliveryItem' WHERE #{quote_column_name(:originator_type)}='IncomingParcelItem'"
        execute "UPDATE #{quote_table_name(:product_readings)} SET #{quote_column_name(:originator_type)}='IncomingDeliveryItem' WHERE #{quote_column_name(:originator_type)}='IncomingParcelItem'"
        execute "UPDATE #{quote_table_name(:products)} SET #{quote_column_name(:type)}='IncomingDeliveryItem' WHERE #{quote_column_name(:type)}='IncomingParcelItem'"
        execute "UPDATE #{quote_table_name(:versions)} SET #{quote_column_name(:item_type)}='IncomingDeliveryItem' WHERE #{quote_column_name(:item_type)}='IncomingParcelItem'"
      end
    end
    # Custom fields
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:custom_fields)} SET #{quote_column_name(:customized_type)}='IncomingParcelItem' WHERE #{quote_column_name(:customized_type)}='IncomingDeliveryItem'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:custom_fields)} SET #{quote_column_name(:customized_type)}='IncomingDeliveryItem' WHERE #{quote_column_name(:customized_type)}='IncomingParcelItem'"
      end
    end
    # Listings
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:listings)} SET #{quote_column_name(:root_model)}='incoming_parcel_item' WHERE #{quote_column_name(:root_model)}='incoming_delivery_item'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:listings)} SET #{quote_column_name(:root_model)}='incoming_delivery_item' WHERE #{quote_column_name(:root_model)}='incoming_parcel_item'"
      end
    end
    # Sequences
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:sequences)} SET #{quote_column_name(:usage)}='incoming_parcel_items' WHERE #{quote_column_name(:usage)}='incoming_delivery_items'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:sequences)} SET #{quote_column_name(:usage)}='incoming_delivery_items' WHERE #{quote_column_name(:usage)}='incoming_parcel_items'"
      end
    end
  end
end
