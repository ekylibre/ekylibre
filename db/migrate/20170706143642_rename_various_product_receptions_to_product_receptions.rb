class RenameVariousProductReceptionsToProductReceptions < ActiveRecord::Migration
  def change
    # Polymorphic columns
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:affairs)} SET #{quote_column_name(:type)}='ProductReception' WHERE #{quote_column_name(:type)}='VariousProductReception'"
        execute "UPDATE #{quote_table_name(:attachments)} SET #{quote_column_name(:resource_type)}='ProductReception' WHERE #{quote_column_name(:resource_type)}='VariousProductReception'"
        execute "UPDATE #{quote_table_name(:call_messages)} SET #{quote_column_name(:type)}='ProductReception' WHERE #{quote_column_name(:type)}='VariousProductReception'"
        execute "UPDATE #{quote_table_name(:calls)} SET #{quote_column_name(:source_type)}='ProductReception' WHERE #{quote_column_name(:source_type)}='VariousProductReception'"
        execute "UPDATE #{quote_table_name(:gaps)} SET #{quote_column_name(:type)}='ProductReception' WHERE #{quote_column_name(:type)}='VariousProductReception'"
        execute "UPDATE #{quote_table_name(:intervention_parameters)} SET #{quote_column_name(:type)}='ProductReception' WHERE #{quote_column_name(:type)}='VariousProductReception'"
        execute "UPDATE #{quote_table_name(:issues)} SET #{quote_column_name(:target_type)}='ProductReception' WHERE #{quote_column_name(:target_type)}='VariousProductReception'"
        execute "UPDATE #{quote_table_name(:journal_entries)} SET #{quote_column_name(:resource_type)}='ProductReception' WHERE #{quote_column_name(:resource_type)}='VariousProductReception'"
        execute "UPDATE #{quote_table_name(:journal_entry_items)} SET #{quote_column_name(:resource_type)}='ProductReception' WHERE #{quote_column_name(:resource_type)}='VariousProductReception'"
        execute "UPDATE #{quote_table_name(:notifications)} SET #{quote_column_name(:target_type)}='ProductReception' WHERE #{quote_column_name(:target_type)}='VariousProductReception'"
        execute "UPDATE #{quote_table_name(:observations)} SET #{quote_column_name(:subject_type)}='ProductReception' WHERE #{quote_column_name(:subject_type)}='VariousProductReception'"
        execute "UPDATE #{quote_table_name(:outgoing_payments)} SET #{quote_column_name(:type)}='ProductReception' WHERE #{quote_column_name(:type)}='VariousProductReception'"
        execute "UPDATE #{quote_table_name(:parcels)} SET #{quote_column_name(:type)}='ProductReception' WHERE #{quote_column_name(:type)}='VariousProductReception'"
        execute "UPDATE #{quote_table_name(:preferences)} SET #{quote_column_name(:record_value_type)}='ProductReception' WHERE #{quote_column_name(:record_value_type)}='VariousProductReception'"
        execute "UPDATE #{quote_table_name(:product_enjoyments)} SET #{quote_column_name(:originator_type)}='ProductReception' WHERE #{quote_column_name(:originator_type)}='VariousProductReception'"
        execute "UPDATE #{quote_table_name(:product_linkages)} SET #{quote_column_name(:originator_type)}='ProductReception' WHERE #{quote_column_name(:originator_type)}='VariousProductReception'"
        execute "UPDATE #{quote_table_name(:product_links)} SET #{quote_column_name(:originator_type)}='ProductReception' WHERE #{quote_column_name(:originator_type)}='VariousProductReception'"
        execute "UPDATE #{quote_table_name(:product_localizations)} SET #{quote_column_name(:originator_type)}='ProductReception' WHERE #{quote_column_name(:originator_type)}='VariousProductReception'"
        execute "UPDATE #{quote_table_name(:product_memberships)} SET #{quote_column_name(:originator_type)}='ProductReception' WHERE #{quote_column_name(:originator_type)}='VariousProductReception'"
        execute "UPDATE #{quote_table_name(:product_movements)} SET #{quote_column_name(:originator_type)}='ProductReception' WHERE #{quote_column_name(:originator_type)}='VariousProductReception'"
        execute "UPDATE #{quote_table_name(:product_ownerships)} SET #{quote_column_name(:originator_type)}='ProductReception' WHERE #{quote_column_name(:originator_type)}='VariousProductReception'"
        execute "UPDATE #{quote_table_name(:product_phases)} SET #{quote_column_name(:originator_type)}='ProductReception' WHERE #{quote_column_name(:originator_type)}='VariousProductReception'"
        execute "UPDATE #{quote_table_name(:product_readings)} SET #{quote_column_name(:originator_type)}='ProductReception' WHERE #{quote_column_name(:originator_type)}='VariousProductReception'"
        execute "UPDATE #{quote_table_name(:products)} SET #{quote_column_name(:type)}='ProductReception' WHERE #{quote_column_name(:type)}='VariousProductReception'"
        execute "UPDATE #{quote_table_name(:synchronization_operations)} SET #{quote_column_name(:originator_type)}='ProductReception' WHERE #{quote_column_name(:originator_type)}='VariousProductReception'"
        execute "UPDATE #{quote_table_name(:versions)} SET #{quote_column_name(:item_type)}='ProductReception' WHERE #{quote_column_name(:item_type)}='VariousProductReception'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:affairs)} SET #{quote_column_name(:type)}='VariousProductReception' WHERE #{quote_column_name(:type)}='ProductReception'"
        execute "UPDATE #{quote_table_name(:attachments)} SET #{quote_column_name(:resource_type)}='VariousProductReception' WHERE #{quote_column_name(:resource_type)}='ProductReception'"
        execute "UPDATE #{quote_table_name(:call_messages)} SET #{quote_column_name(:type)}='VariousProductReception' WHERE #{quote_column_name(:type)}='ProductReception'"
        execute "UPDATE #{quote_table_name(:calls)} SET #{quote_column_name(:source_type)}='VariousProductReception' WHERE #{quote_column_name(:source_type)}='ProductReception'"
        execute "UPDATE #{quote_table_name(:gaps)} SET #{quote_column_name(:type)}='VariousProductReception' WHERE #{quote_column_name(:type)}='ProductReception'"
        execute "UPDATE #{quote_table_name(:intervention_parameters)} SET #{quote_column_name(:type)}='VariousProductReception' WHERE #{quote_column_name(:type)}='ProductReception'"
        execute "UPDATE #{quote_table_name(:issues)} SET #{quote_column_name(:target_type)}='VariousProductReception' WHERE #{quote_column_name(:target_type)}='ProductReception'"
        execute "UPDATE #{quote_table_name(:journal_entries)} SET #{quote_column_name(:resource_type)}='VariousProductReception' WHERE #{quote_column_name(:resource_type)}='ProductReception'"
        execute "UPDATE #{quote_table_name(:journal_entry_items)} SET #{quote_column_name(:resource_type)}='VariousProductReception' WHERE #{quote_column_name(:resource_type)}='ProductReception'"
        execute "UPDATE #{quote_table_name(:notifications)} SET #{quote_column_name(:target_type)}='VariousProductReception' WHERE #{quote_column_name(:target_type)}='ProductReception'"
        execute "UPDATE #{quote_table_name(:observations)} SET #{quote_column_name(:subject_type)}='VariousProductReception' WHERE #{quote_column_name(:subject_type)}='ProductReception'"
        execute "UPDATE #{quote_table_name(:outgoing_payments)} SET #{quote_column_name(:type)}='VariousProductReception' WHERE #{quote_column_name(:type)}='ProductReception'"
        execute "UPDATE #{quote_table_name(:parcels)} SET #{quote_column_name(:type)}='VariousProductReception' WHERE #{quote_column_name(:type)}='ProductReception'"
        execute "UPDATE #{quote_table_name(:preferences)} SET #{quote_column_name(:record_value_type)}='VariousProductReception' WHERE #{quote_column_name(:record_value_type)}='ProductReception'"
        execute "UPDATE #{quote_table_name(:product_enjoyments)} SET #{quote_column_name(:originator_type)}='VariousProductReception' WHERE #{quote_column_name(:originator_type)}='ProductReception'"
        execute "UPDATE #{quote_table_name(:product_linkages)} SET #{quote_column_name(:originator_type)}='VariousProductReception' WHERE #{quote_column_name(:originator_type)}='ProductReception'"
        execute "UPDATE #{quote_table_name(:product_links)} SET #{quote_column_name(:originator_type)}='VariousProductReception' WHERE #{quote_column_name(:originator_type)}='ProductReception'"
        execute "UPDATE #{quote_table_name(:product_localizations)} SET #{quote_column_name(:originator_type)}='VariousProductReception' WHERE #{quote_column_name(:originator_type)}='ProductReception'"
        execute "UPDATE #{quote_table_name(:product_memberships)} SET #{quote_column_name(:originator_type)}='VariousProductReception' WHERE #{quote_column_name(:originator_type)}='ProductReception'"
        execute "UPDATE #{quote_table_name(:product_movements)} SET #{quote_column_name(:originator_type)}='VariousProductReception' WHERE #{quote_column_name(:originator_type)}='ProductReception'"
        execute "UPDATE #{quote_table_name(:product_ownerships)} SET #{quote_column_name(:originator_type)}='VariousProductReception' WHERE #{quote_column_name(:originator_type)}='ProductReception'"
        execute "UPDATE #{quote_table_name(:product_phases)} SET #{quote_column_name(:originator_type)}='VariousProductReception' WHERE #{quote_column_name(:originator_type)}='ProductReception'"
        execute "UPDATE #{quote_table_name(:product_readings)} SET #{quote_column_name(:originator_type)}='VariousProductReception' WHERE #{quote_column_name(:originator_type)}='ProductReception'"
        execute "UPDATE #{quote_table_name(:products)} SET #{quote_column_name(:type)}='VariousProductReception' WHERE #{quote_column_name(:type)}='ProductReception'"
        execute "UPDATE #{quote_table_name(:synchronization_operations)} SET #{quote_column_name(:originator_type)}='VariousProductReception' WHERE #{quote_column_name(:originator_type)}='ProductReception'"
        execute "UPDATE #{quote_table_name(:versions)} SET #{quote_column_name(:item_type)}='VariousProductReception' WHERE #{quote_column_name(:item_type)}='ProductReception'"
      end
    end
    # Custom fields
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:custom_fields)} SET #{quote_column_name(:customized_type)}='ProductReception' WHERE #{quote_column_name(:customized_type)}='VariousProductReception'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:custom_fields)} SET #{quote_column_name(:customized_type)}='VariousProductReception' WHERE #{quote_column_name(:customized_type)}='ProductReception'"
      end
    end
    # Listings
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:listings)} SET #{quote_column_name(:root_model)}='product_reception' WHERE #{quote_column_name(:root_model)}='various_product_reception'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:listings)} SET #{quote_column_name(:root_model)}='various_product_reception' WHERE #{quote_column_name(:root_model)}='product_reception'"
      end
    end
    # Sequences
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:sequences)} SET #{quote_column_name(:usage)}='product_receptions' WHERE #{quote_column_name(:usage)}='various_product_receptions'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:sequences)} SET #{quote_column_name(:usage)}='various_product_receptions' WHERE #{quote_column_name(:usage)}='product_receptions'"
      end
    end

    # Add your specific code here...
  end
end
