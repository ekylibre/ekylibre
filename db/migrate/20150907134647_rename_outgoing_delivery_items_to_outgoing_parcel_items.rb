class RenameOutgoingDeliveryItemsToOutgoingParcelItems < ActiveRecord::Migration

  def change
    rename_table :outgoing_delivery_items, :outgoing_parcel_items
    # Polymorphic columns
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:affairs)} SET #{quote_column_name(:type)}='OutgoingParcelItem' WHERE #{quote_column_name(:type)}='OutgoingDeliveryItem'"
        execute "UPDATE #{quote_table_name(:attachments)} SET #{quote_column_name(:resource_type)}='OutgoingParcelItem' WHERE #{quote_column_name(:resource_type)}='OutgoingDeliveryItem'"
        execute "UPDATE #{quote_table_name(:issues)} SET #{quote_column_name(:target_type)}='OutgoingParcelItem' WHERE #{quote_column_name(:target_type)}='OutgoingDeliveryItem'"
        execute "UPDATE #{quote_table_name(:journal_entries)} SET #{quote_column_name(:resource_type)}='OutgoingParcelItem' WHERE #{quote_column_name(:resource_type)}='OutgoingDeliveryItem'"
        execute "UPDATE #{quote_table_name(:observations)} SET #{quote_column_name(:subject_type)}='OutgoingParcelItem' WHERE #{quote_column_name(:subject_type)}='OutgoingDeliveryItem'"
        execute "UPDATE #{quote_table_name(:preferences)} SET #{quote_column_name(:record_value_type)}='OutgoingParcelItem' WHERE #{quote_column_name(:record_value_type)}='OutgoingDeliveryItem'"
        execute "UPDATE #{quote_table_name(:product_enjoyments)} SET #{quote_column_name(:originator_type)}='OutgoingParcelItem' WHERE #{quote_column_name(:originator_type)}='OutgoingDeliveryItem'"
        execute "UPDATE #{quote_table_name(:product_junctions)} SET #{quote_column_name(:originator_type)}='OutgoingParcelItem' WHERE #{quote_column_name(:originator_type)}='OutgoingDeliveryItem'"
        execute "UPDATE #{quote_table_name(:product_linkages)} SET #{quote_column_name(:originator_type)}='OutgoingParcelItem' WHERE #{quote_column_name(:originator_type)}='OutgoingDeliveryItem'"
        execute "UPDATE #{quote_table_name(:product_links)} SET #{quote_column_name(:originator_type)}='OutgoingParcelItem' WHERE #{quote_column_name(:originator_type)}='OutgoingDeliveryItem'"
        execute "UPDATE #{quote_table_name(:product_localizations)} SET #{quote_column_name(:originator_type)}='OutgoingParcelItem' WHERE #{quote_column_name(:originator_type)}='OutgoingDeliveryItem'"
        execute "UPDATE #{quote_table_name(:product_memberships)} SET #{quote_column_name(:originator_type)}='OutgoingParcelItem' WHERE #{quote_column_name(:originator_type)}='OutgoingDeliveryItem'"
        execute "UPDATE #{quote_table_name(:product_ownerships)} SET #{quote_column_name(:originator_type)}='OutgoingParcelItem' WHERE #{quote_column_name(:originator_type)}='OutgoingDeliveryItem'"
        execute "UPDATE #{quote_table_name(:product_phases)} SET #{quote_column_name(:originator_type)}='OutgoingParcelItem' WHERE #{quote_column_name(:originator_type)}='OutgoingDeliveryItem'"
        execute "UPDATE #{quote_table_name(:product_reading_tasks)} SET #{quote_column_name(:originator_type)}='OutgoingParcelItem' WHERE #{quote_column_name(:originator_type)}='OutgoingDeliveryItem'"
        execute "UPDATE #{quote_table_name(:product_readings)} SET #{quote_column_name(:originator_type)}='OutgoingParcelItem' WHERE #{quote_column_name(:originator_type)}='OutgoingDeliveryItem'"
        execute "UPDATE #{quote_table_name(:products)} SET #{quote_column_name(:type)}='OutgoingParcelItem' WHERE #{quote_column_name(:type)}='OutgoingDeliveryItem'"
        execute "UPDATE #{quote_table_name(:versions)} SET #{quote_column_name(:item_type)}='OutgoingParcelItem' WHERE #{quote_column_name(:item_type)}='OutgoingDeliveryItem'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:affairs)} SET #{quote_column_name(:type)}='OutgoingDeliveryItem' WHERE #{quote_column_name(:type)}='OutgoingParcelItem'"
        execute "UPDATE #{quote_table_name(:attachments)} SET #{quote_column_name(:resource_type)}='OutgoingDeliveryItem' WHERE #{quote_column_name(:resource_type)}='OutgoingParcelItem'"
        execute "UPDATE #{quote_table_name(:issues)} SET #{quote_column_name(:target_type)}='OutgoingDeliveryItem' WHERE #{quote_column_name(:target_type)}='OutgoingParcelItem'"
        execute "UPDATE #{quote_table_name(:journal_entries)} SET #{quote_column_name(:resource_type)}='OutgoingDeliveryItem' WHERE #{quote_column_name(:resource_type)}='OutgoingParcelItem'"
        execute "UPDATE #{quote_table_name(:observations)} SET #{quote_column_name(:subject_type)}='OutgoingDeliveryItem' WHERE #{quote_column_name(:subject_type)}='OutgoingParcelItem'"
        execute "UPDATE #{quote_table_name(:preferences)} SET #{quote_column_name(:record_value_type)}='OutgoingDeliveryItem' WHERE #{quote_column_name(:record_value_type)}='OutgoingParcelItem'"
        execute "UPDATE #{quote_table_name(:product_enjoyments)} SET #{quote_column_name(:originator_type)}='OutgoingDeliveryItem' WHERE #{quote_column_name(:originator_type)}='OutgoingParcelItem'"
        execute "UPDATE #{quote_table_name(:product_junctions)} SET #{quote_column_name(:originator_type)}='OutgoingDeliveryItem' WHERE #{quote_column_name(:originator_type)}='OutgoingParcelItem'"
        execute "UPDATE #{quote_table_name(:product_linkages)} SET #{quote_column_name(:originator_type)}='OutgoingDeliveryItem' WHERE #{quote_column_name(:originator_type)}='OutgoingParcelItem'"
        execute "UPDATE #{quote_table_name(:product_links)} SET #{quote_column_name(:originator_type)}='OutgoingDeliveryItem' WHERE #{quote_column_name(:originator_type)}='OutgoingParcelItem'"
        execute "UPDATE #{quote_table_name(:product_localizations)} SET #{quote_column_name(:originator_type)}='OutgoingDeliveryItem' WHERE #{quote_column_name(:originator_type)}='OutgoingParcelItem'"
        execute "UPDATE #{quote_table_name(:product_memberships)} SET #{quote_column_name(:originator_type)}='OutgoingDeliveryItem' WHERE #{quote_column_name(:originator_type)}='OutgoingParcelItem'"
        execute "UPDATE #{quote_table_name(:product_ownerships)} SET #{quote_column_name(:originator_type)}='OutgoingDeliveryItem' WHERE #{quote_column_name(:originator_type)}='OutgoingParcelItem'"
        execute "UPDATE #{quote_table_name(:product_phases)} SET #{quote_column_name(:originator_type)}='OutgoingDeliveryItem' WHERE #{quote_column_name(:originator_type)}='OutgoingParcelItem'"
        execute "UPDATE #{quote_table_name(:product_reading_tasks)} SET #{quote_column_name(:originator_type)}='OutgoingDeliveryItem' WHERE #{quote_column_name(:originator_type)}='OutgoingParcelItem'"
        execute "UPDATE #{quote_table_name(:product_readings)} SET #{quote_column_name(:originator_type)}='OutgoingDeliveryItem' WHERE #{quote_column_name(:originator_type)}='OutgoingParcelItem'"
        execute "UPDATE #{quote_table_name(:products)} SET #{quote_column_name(:type)}='OutgoingDeliveryItem' WHERE #{quote_column_name(:type)}='OutgoingParcelItem'"
        execute "UPDATE #{quote_table_name(:versions)} SET #{quote_column_name(:item_type)}='OutgoingDeliveryItem' WHERE #{quote_column_name(:item_type)}='OutgoingParcelItem'"
      end
    end
    # Custom fields
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:custom_fields)} SET #{quote_column_name(:customized_type)}='OutgoingParcelItem' WHERE #{quote_column_name(:customized_type)}='OutgoingDeliveryItem'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:custom_fields)} SET #{quote_column_name(:customized_type)}='OutgoingDeliveryItem' WHERE #{quote_column_name(:customized_type)}='OutgoingParcelItem'"
      end
    end
    # Listings
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:listings)} SET #{quote_column_name(:root_model)}='outgoing_parcel_item' WHERE #{quote_column_name(:root_model)}='outgoing_delivery_item'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:listings)} SET #{quote_column_name(:root_model)}='outgoing_delivery_item' WHERE #{quote_column_name(:root_model)}='outgoing_parcel_item'"
      end
    end
    # Sequences
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:sequences)} SET #{quote_column_name(:usage)}='outgoing_parcel_items' WHERE #{quote_column_name(:usage)}='outgoing_delivery_items'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:sequences)} SET #{quote_column_name(:usage)}='outgoing_delivery_items' WHERE #{quote_column_name(:usage)}='outgoing_parcel_items'"
      end
    end

    # Add your specific code here...

  end

end
