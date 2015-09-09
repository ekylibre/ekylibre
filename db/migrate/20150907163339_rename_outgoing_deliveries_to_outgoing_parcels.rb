class RenameOutgoingDeliveriesToOutgoingParcels < ActiveRecord::Migration

  def change
    rename_table :outgoing_deliveries, :outgoing_parcels
    # Polymorphic columns
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:affairs)} SET #{quote_column_name(:type)}='OutgoingParcel' WHERE #{quote_column_name(:type)}='OutgoingDelivery'"
        execute "UPDATE #{quote_table_name(:attachments)} SET #{quote_column_name(:resource_type)}='OutgoingParcel' WHERE #{quote_column_name(:resource_type)}='OutgoingDelivery'"
        execute "UPDATE #{quote_table_name(:issues)} SET #{quote_column_name(:target_type)}='OutgoingParcel' WHERE #{quote_column_name(:target_type)}='OutgoingDelivery'"
        execute "UPDATE #{quote_table_name(:journal_entries)} SET #{quote_column_name(:resource_type)}='OutgoingParcel' WHERE #{quote_column_name(:resource_type)}='OutgoingDelivery'"
        execute "UPDATE #{quote_table_name(:observations)} SET #{quote_column_name(:subject_type)}='OutgoingParcel' WHERE #{quote_column_name(:subject_type)}='OutgoingDelivery'"
        execute "UPDATE #{quote_table_name(:preferences)} SET #{quote_column_name(:record_value_type)}='OutgoingParcel' WHERE #{quote_column_name(:record_value_type)}='OutgoingDelivery'"
        execute "UPDATE #{quote_table_name(:product_enjoyments)} SET #{quote_column_name(:originator_type)}='OutgoingParcel' WHERE #{quote_column_name(:originator_type)}='OutgoingDelivery'"
        execute "UPDATE #{quote_table_name(:product_junctions)} SET #{quote_column_name(:originator_type)}='OutgoingParcel' WHERE #{quote_column_name(:originator_type)}='OutgoingDelivery'"
        execute "UPDATE #{quote_table_name(:product_linkages)} SET #{quote_column_name(:originator_type)}='OutgoingParcel' WHERE #{quote_column_name(:originator_type)}='OutgoingDelivery'"
        execute "UPDATE #{quote_table_name(:product_links)} SET #{quote_column_name(:originator_type)}='OutgoingParcel' WHERE #{quote_column_name(:originator_type)}='OutgoingDelivery'"
        execute "UPDATE #{quote_table_name(:product_localizations)} SET #{quote_column_name(:originator_type)}='OutgoingParcel' WHERE #{quote_column_name(:originator_type)}='OutgoingDelivery'"
        execute "UPDATE #{quote_table_name(:product_memberships)} SET #{quote_column_name(:originator_type)}='OutgoingParcel' WHERE #{quote_column_name(:originator_type)}='OutgoingDelivery'"
        execute "UPDATE #{quote_table_name(:product_ownerships)} SET #{quote_column_name(:originator_type)}='OutgoingParcel' WHERE #{quote_column_name(:originator_type)}='OutgoingDelivery'"
        execute "UPDATE #{quote_table_name(:product_phases)} SET #{quote_column_name(:originator_type)}='OutgoingParcel' WHERE #{quote_column_name(:originator_type)}='OutgoingDelivery'"
        execute "UPDATE #{quote_table_name(:product_reading_tasks)} SET #{quote_column_name(:originator_type)}='OutgoingParcel' WHERE #{quote_column_name(:originator_type)}='OutgoingDelivery'"
        execute "UPDATE #{quote_table_name(:product_readings)} SET #{quote_column_name(:originator_type)}='OutgoingParcel' WHERE #{quote_column_name(:originator_type)}='OutgoingDelivery'"
        execute "UPDATE #{quote_table_name(:products)} SET #{quote_column_name(:type)}='OutgoingParcel' WHERE #{quote_column_name(:type)}='OutgoingDelivery'"
        execute "UPDATE #{quote_table_name(:versions)} SET #{quote_column_name(:item_type)}='OutgoingParcel' WHERE #{quote_column_name(:item_type)}='OutgoingDelivery'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:affairs)} SET #{quote_column_name(:type)}='OutgoingDelivery' WHERE #{quote_column_name(:type)}='OutgoingParcel'"
        execute "UPDATE #{quote_table_name(:attachments)} SET #{quote_column_name(:resource_type)}='OutgoingDelivery' WHERE #{quote_column_name(:resource_type)}='OutgoingParcel'"
        execute "UPDATE #{quote_table_name(:issues)} SET #{quote_column_name(:target_type)}='OutgoingDelivery' WHERE #{quote_column_name(:target_type)}='OutgoingParcel'"
        execute "UPDATE #{quote_table_name(:journal_entries)} SET #{quote_column_name(:resource_type)}='OutgoingDelivery' WHERE #{quote_column_name(:resource_type)}='OutgoingParcel'"
        execute "UPDATE #{quote_table_name(:observations)} SET #{quote_column_name(:subject_type)}='OutgoingDelivery' WHERE #{quote_column_name(:subject_type)}='OutgoingParcel'"
        execute "UPDATE #{quote_table_name(:preferences)} SET #{quote_column_name(:record_value_type)}='OutgoingDelivery' WHERE #{quote_column_name(:record_value_type)}='OutgoingParcel'"
        execute "UPDATE #{quote_table_name(:product_enjoyments)} SET #{quote_column_name(:originator_type)}='OutgoingDelivery' WHERE #{quote_column_name(:originator_type)}='OutgoingParcel'"
        execute "UPDATE #{quote_table_name(:product_junctions)} SET #{quote_column_name(:originator_type)}='OutgoingDelivery' WHERE #{quote_column_name(:originator_type)}='OutgoingParcel'"
        execute "UPDATE #{quote_table_name(:product_linkages)} SET #{quote_column_name(:originator_type)}='OutgoingDelivery' WHERE #{quote_column_name(:originator_type)}='OutgoingParcel'"
        execute "UPDATE #{quote_table_name(:product_links)} SET #{quote_column_name(:originator_type)}='OutgoingDelivery' WHERE #{quote_column_name(:originator_type)}='OutgoingParcel'"
        execute "UPDATE #{quote_table_name(:product_localizations)} SET #{quote_column_name(:originator_type)}='OutgoingDelivery' WHERE #{quote_column_name(:originator_type)}='OutgoingParcel'"
        execute "UPDATE #{quote_table_name(:product_memberships)} SET #{quote_column_name(:originator_type)}='OutgoingDelivery' WHERE #{quote_column_name(:originator_type)}='OutgoingParcel'"
        execute "UPDATE #{quote_table_name(:product_ownerships)} SET #{quote_column_name(:originator_type)}='OutgoingDelivery' WHERE #{quote_column_name(:originator_type)}='OutgoingParcel'"
        execute "UPDATE #{quote_table_name(:product_phases)} SET #{quote_column_name(:originator_type)}='OutgoingDelivery' WHERE #{quote_column_name(:originator_type)}='OutgoingParcel'"
        execute "UPDATE #{quote_table_name(:product_reading_tasks)} SET #{quote_column_name(:originator_type)}='OutgoingDelivery' WHERE #{quote_column_name(:originator_type)}='OutgoingParcel'"
        execute "UPDATE #{quote_table_name(:product_readings)} SET #{quote_column_name(:originator_type)}='OutgoingDelivery' WHERE #{quote_column_name(:originator_type)}='OutgoingParcel'"
        execute "UPDATE #{quote_table_name(:products)} SET #{quote_column_name(:type)}='OutgoingDelivery' WHERE #{quote_column_name(:type)}='OutgoingParcel'"
        execute "UPDATE #{quote_table_name(:versions)} SET #{quote_column_name(:item_type)}='OutgoingDelivery' WHERE #{quote_column_name(:item_type)}='OutgoingParcel'"
      end
    end
    # Custom fields
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:custom_fields)} SET #{quote_column_name(:customized_type)}='OutgoingParcel' WHERE #{quote_column_name(:customized_type)}='OutgoingDelivery'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:custom_fields)} SET #{quote_column_name(:customized_type)}='OutgoingDelivery' WHERE #{quote_column_name(:customized_type)}='OutgoingParcel'"
      end
    end
    # Listings
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:listings)} SET #{quote_column_name(:root_model)}='outgoing_parcel' WHERE #{quote_column_name(:root_model)}='outgoing_delivery'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:listings)} SET #{quote_column_name(:root_model)}='outgoing_delivery' WHERE #{quote_column_name(:root_model)}='outgoing_parcel'"
      end
    end
    # Sequences
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:sequences)} SET #{quote_column_name(:usage)}='outgoing_parcels' WHERE #{quote_column_name(:usage)}='outgoing_deliveries'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:sequences)} SET #{quote_column_name(:usage)}='outgoing_deliveries' WHERE #{quote_column_name(:usage)}='outgoing_parcels'"
      end
    end

    # Add your specific code here...

  end

end
