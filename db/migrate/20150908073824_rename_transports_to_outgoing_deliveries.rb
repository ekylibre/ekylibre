class RenameTransportsToOutgoingDeliveries < ActiveRecord::Migration
  def change
    rename_table :transports, :outgoing_deliveries
    # Polymorphic columns
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:affairs)} SET #{quote_column_name(:type)}='OutgoingDelivery' WHERE #{quote_column_name(:type)}='Transport'"
        execute "UPDATE #{quote_table_name(:attachments)} SET #{quote_column_name(:resource_type)}='OutgoingDelivery' WHERE #{quote_column_name(:resource_type)}='Transport'"
        execute "UPDATE #{quote_table_name(:issues)} SET #{quote_column_name(:target_type)}='OutgoingDelivery' WHERE #{quote_column_name(:target_type)}='Transport'"
        execute "UPDATE #{quote_table_name(:journal_entries)} SET #{quote_column_name(:resource_type)}='OutgoingDelivery' WHERE #{quote_column_name(:resource_type)}='Transport'"
        execute "UPDATE #{quote_table_name(:observations)} SET #{quote_column_name(:subject_type)}='OutgoingDelivery' WHERE #{quote_column_name(:subject_type)}='Transport'"
        execute "UPDATE #{quote_table_name(:preferences)} SET #{quote_column_name(:record_value_type)}='OutgoingDelivery' WHERE #{quote_column_name(:record_value_type)}='Transport'"
        execute "UPDATE #{quote_table_name(:product_enjoyments)} SET #{quote_column_name(:originator_type)}='OutgoingDelivery' WHERE #{quote_column_name(:originator_type)}='Transport'"
        execute "UPDATE #{quote_table_name(:product_junctions)} SET #{quote_column_name(:originator_type)}='OutgoingDelivery' WHERE #{quote_column_name(:originator_type)}='Transport'"
        execute "UPDATE #{quote_table_name(:product_linkages)} SET #{quote_column_name(:originator_type)}='OutgoingDelivery' WHERE #{quote_column_name(:originator_type)}='Transport'"
        execute "UPDATE #{quote_table_name(:product_links)} SET #{quote_column_name(:originator_type)}='OutgoingDelivery' WHERE #{quote_column_name(:originator_type)}='Transport'"
        execute "UPDATE #{quote_table_name(:product_localizations)} SET #{quote_column_name(:originator_type)}='OutgoingDelivery' WHERE #{quote_column_name(:originator_type)}='Transport'"
        execute "UPDATE #{quote_table_name(:product_memberships)} SET #{quote_column_name(:originator_type)}='OutgoingDelivery' WHERE #{quote_column_name(:originator_type)}='Transport'"
        execute "UPDATE #{quote_table_name(:product_ownerships)} SET #{quote_column_name(:originator_type)}='OutgoingDelivery' WHERE #{quote_column_name(:originator_type)}='Transport'"
        execute "UPDATE #{quote_table_name(:product_phases)} SET #{quote_column_name(:originator_type)}='OutgoingDelivery' WHERE #{quote_column_name(:originator_type)}='Transport'"
        execute "UPDATE #{quote_table_name(:product_reading_tasks)} SET #{quote_column_name(:originator_type)}='OutgoingDelivery' WHERE #{quote_column_name(:originator_type)}='Transport'"
        execute "UPDATE #{quote_table_name(:product_readings)} SET #{quote_column_name(:originator_type)}='OutgoingDelivery' WHERE #{quote_column_name(:originator_type)}='Transport'"
        execute "UPDATE #{quote_table_name(:products)} SET #{quote_column_name(:type)}='OutgoingDelivery' WHERE #{quote_column_name(:type)}='Transport'"
        execute "UPDATE #{quote_table_name(:versions)} SET #{quote_column_name(:item_type)}='OutgoingDelivery' WHERE #{quote_column_name(:item_type)}='Transport'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:affairs)} SET #{quote_column_name(:type)}='Transport' WHERE #{quote_column_name(:type)}='OutgoingDelivery'"
        execute "UPDATE #{quote_table_name(:attachments)} SET #{quote_column_name(:resource_type)}='Transport' WHERE #{quote_column_name(:resource_type)}='OutgoingDelivery'"
        execute "UPDATE #{quote_table_name(:issues)} SET #{quote_column_name(:target_type)}='Transport' WHERE #{quote_column_name(:target_type)}='OutgoingDelivery'"
        execute "UPDATE #{quote_table_name(:journal_entries)} SET #{quote_column_name(:resource_type)}='Transport' WHERE #{quote_column_name(:resource_type)}='OutgoingDelivery'"
        execute "UPDATE #{quote_table_name(:observations)} SET #{quote_column_name(:subject_type)}='Transport' WHERE #{quote_column_name(:subject_type)}='OutgoingDelivery'"
        execute "UPDATE #{quote_table_name(:preferences)} SET #{quote_column_name(:record_value_type)}='Transport' WHERE #{quote_column_name(:record_value_type)}='OutgoingDelivery'"
        execute "UPDATE #{quote_table_name(:product_enjoyments)} SET #{quote_column_name(:originator_type)}='Transport' WHERE #{quote_column_name(:originator_type)}='OutgoingDelivery'"
        execute "UPDATE #{quote_table_name(:product_junctions)} SET #{quote_column_name(:originator_type)}='Transport' WHERE #{quote_column_name(:originator_type)}='OutgoingDelivery'"
        execute "UPDATE #{quote_table_name(:product_linkages)} SET #{quote_column_name(:originator_type)}='Transport' WHERE #{quote_column_name(:originator_type)}='OutgoingDelivery'"
        execute "UPDATE #{quote_table_name(:product_links)} SET #{quote_column_name(:originator_type)}='Transport' WHERE #{quote_column_name(:originator_type)}='OutgoingDelivery'"
        execute "UPDATE #{quote_table_name(:product_localizations)} SET #{quote_column_name(:originator_type)}='Transport' WHERE #{quote_column_name(:originator_type)}='OutgoingDelivery'"
        execute "UPDATE #{quote_table_name(:product_memberships)} SET #{quote_column_name(:originator_type)}='Transport' WHERE #{quote_column_name(:originator_type)}='OutgoingDelivery'"
        execute "UPDATE #{quote_table_name(:product_ownerships)} SET #{quote_column_name(:originator_type)}='Transport' WHERE #{quote_column_name(:originator_type)}='OutgoingDelivery'"
        execute "UPDATE #{quote_table_name(:product_phases)} SET #{quote_column_name(:originator_type)}='Transport' WHERE #{quote_column_name(:originator_type)}='OutgoingDelivery'"
        execute "UPDATE #{quote_table_name(:product_reading_tasks)} SET #{quote_column_name(:originator_type)}='Transport' WHERE #{quote_column_name(:originator_type)}='OutgoingDelivery'"
        execute "UPDATE #{quote_table_name(:product_readings)} SET #{quote_column_name(:originator_type)}='Transport' WHERE #{quote_column_name(:originator_type)}='OutgoingDelivery'"
        execute "UPDATE #{quote_table_name(:products)} SET #{quote_column_name(:type)}='Transport' WHERE #{quote_column_name(:type)}='OutgoingDelivery'"
        execute "UPDATE #{quote_table_name(:versions)} SET #{quote_column_name(:item_type)}='Transport' WHERE #{quote_column_name(:item_type)}='OutgoingDelivery'"
      end
    end
    # Custom fields
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:custom_fields)} SET #{quote_column_name(:customized_type)}='OutgoingDelivery' WHERE #{quote_column_name(:customized_type)}='Transport'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:custom_fields)} SET #{quote_column_name(:customized_type)}='Transport' WHERE #{quote_column_name(:customized_type)}='OutgoingDelivery'"
      end
    end
    # Listings
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:listings)} SET #{quote_column_name(:root_model)}='outgoing_delivery' WHERE #{quote_column_name(:root_model)}='transport'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:listings)} SET #{quote_column_name(:root_model)}='transport' WHERE #{quote_column_name(:root_model)}='outgoing_delivery'"
      end
    end
    # Sequences
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:sequences)} SET #{quote_column_name(:usage)}='outgoing_deliveries' WHERE #{quote_column_name(:usage)}='transports'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:sequences)} SET #{quote_column_name(:usage)}='transports' WHERE #{quote_column_name(:usage)}='outgoing_deliveries'"
      end
    end

    rename_column :outgoing_parcel_items, :delivery_id, :parcel_id
    rename_column :outgoing_parcels, :transport_id, :delivery_id
  end
end
