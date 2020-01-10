class RenameInterventionCostsToInterventionCostings < ActiveRecord::Migration
  def change
    rename_table :intervention_costs, :intervention_costings
    add_column :intervention_costings, :created_at, :datetime
    add_column :intervention_costings, :updated_at, :datetime
    add_column :intervention_costings, :creator_id, :integer
    add_column :intervention_costings, :updater_id, :integer
    add_column :intervention_costings, :lock_version, :integer, null: false, default: 0
    add_index :intervention_costings, :creator_id
    add_index :intervention_costings, :updater_id
    # Polymorphic columns
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:affairs)} SET #{quote_column_name(:type)}='InterventionCosting' WHERE #{quote_column_name(:type)}='InterventionCosts'"
        execute "UPDATE #{quote_table_name(:attachments)} SET #{quote_column_name(:resource_type)}='InterventionCosting' WHERE #{quote_column_name(:resource_type)}='InterventionCosts'"
        execute "UPDATE #{quote_table_name(:call_messages)} SET #{quote_column_name(:type)}='InterventionCosting' WHERE #{quote_column_name(:type)}='InterventionCosts'"
        execute "UPDATE #{quote_table_name(:calls)} SET #{quote_column_name(:source_type)}='InterventionCosting' WHERE #{quote_column_name(:source_type)}='InterventionCosts'"
        execute "UPDATE #{quote_table_name(:gaps)} SET #{quote_column_name(:type)}='InterventionCosting' WHERE #{quote_column_name(:type)}='InterventionCosts'"
        execute "UPDATE #{quote_table_name(:intervention_parameters)} SET #{quote_column_name(:type)}='InterventionCosting' WHERE #{quote_column_name(:type)}='InterventionCosts'"
        execute "UPDATE #{quote_table_name(:issues)} SET #{quote_column_name(:target_type)}='InterventionCosting' WHERE #{quote_column_name(:target_type)}='InterventionCosts'"
        execute "UPDATE #{quote_table_name(:journal_entries)} SET #{quote_column_name(:resource_type)}='InterventionCosting' WHERE #{quote_column_name(:resource_type)}='InterventionCosts'"
        execute "UPDATE #{quote_table_name(:journal_entry_items)} SET #{quote_column_name(:resource_type)}='InterventionCosting' WHERE #{quote_column_name(:resource_type)}='InterventionCosts'"
        execute "UPDATE #{quote_table_name(:naming_format_fields)} SET #{quote_column_name(:type)}='InterventionCosting' WHERE #{quote_column_name(:type)}='InterventionCosts'"
        execute "UPDATE #{quote_table_name(:naming_formats)} SET #{quote_column_name(:type)}='InterventionCosting' WHERE #{quote_column_name(:type)}='InterventionCosts'"
        execute "UPDATE #{quote_table_name(:notifications)} SET #{quote_column_name(:target_type)}='InterventionCosting' WHERE #{quote_column_name(:target_type)}='InterventionCosts'"
        execute "UPDATE #{quote_table_name(:observations)} SET #{quote_column_name(:subject_type)}='InterventionCosting' WHERE #{quote_column_name(:subject_type)}='InterventionCosts'"
        execute "UPDATE #{quote_table_name(:outgoing_payments)} SET #{quote_column_name(:type)}='InterventionCosting' WHERE #{quote_column_name(:type)}='InterventionCosts'"
        execute "UPDATE #{quote_table_name(:parcel_items)} SET #{quote_column_name(:type)}='InterventionCosting' WHERE #{quote_column_name(:type)}='InterventionCosts'"
        execute "UPDATE #{quote_table_name(:parcels)} SET #{quote_column_name(:type)}='InterventionCosting' WHERE #{quote_column_name(:type)}='InterventionCosts'"
        execute "UPDATE #{quote_table_name(:preferences)} SET #{quote_column_name(:record_value_type)}='InterventionCosting' WHERE #{quote_column_name(:record_value_type)}='InterventionCosts'"
        execute "UPDATE #{quote_table_name(:product_enjoyments)} SET #{quote_column_name(:originator_type)}='InterventionCosting' WHERE #{quote_column_name(:originator_type)}='InterventionCosts'"
        execute "UPDATE #{quote_table_name(:product_linkages)} SET #{quote_column_name(:originator_type)}='InterventionCosting' WHERE #{quote_column_name(:originator_type)}='InterventionCosts'"
        execute "UPDATE #{quote_table_name(:product_links)} SET #{quote_column_name(:originator_type)}='InterventionCosting' WHERE #{quote_column_name(:originator_type)}='InterventionCosts'"
        execute "UPDATE #{quote_table_name(:product_localizations)} SET #{quote_column_name(:originator_type)}='InterventionCosting' WHERE #{quote_column_name(:originator_type)}='InterventionCosts'"
        execute "UPDATE #{quote_table_name(:product_memberships)} SET #{quote_column_name(:originator_type)}='InterventionCosting' WHERE #{quote_column_name(:originator_type)}='InterventionCosts'"
        execute "UPDATE #{quote_table_name(:product_movements)} SET #{quote_column_name(:originator_type)}='InterventionCosting' WHERE #{quote_column_name(:originator_type)}='InterventionCosts'"
        execute "UPDATE #{quote_table_name(:product_ownerships)} SET #{quote_column_name(:originator_type)}='InterventionCosting' WHERE #{quote_column_name(:originator_type)}='InterventionCosts'"
        execute "UPDATE #{quote_table_name(:product_phases)} SET #{quote_column_name(:originator_type)}='InterventionCosting' WHERE #{quote_column_name(:originator_type)}='InterventionCosts'"
        execute "UPDATE #{quote_table_name(:product_readings)} SET #{quote_column_name(:originator_type)}='InterventionCosting' WHERE #{quote_column_name(:originator_type)}='InterventionCosts'"
        execute "UPDATE #{quote_table_name(:products)} SET #{quote_column_name(:type)}='InterventionCosting' WHERE #{quote_column_name(:type)}='InterventionCosts'"
        execute "UPDATE #{quote_table_name(:purchases)} SET #{quote_column_name(:type)}='InterventionCosting' WHERE #{quote_column_name(:type)}='InterventionCosts'"
        execute "UPDATE #{quote_table_name(:synchronization_operations)} SET #{quote_column_name(:originator_type)}='InterventionCosting' WHERE #{quote_column_name(:originator_type)}='InterventionCosts'"
        execute "UPDATE #{quote_table_name(:versions)} SET #{quote_column_name(:item_type)}='InterventionCosting' WHERE #{quote_column_name(:item_type)}='InterventionCosts'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:affairs)} SET #{quote_column_name(:type)}='InterventionCosts' WHERE #{quote_column_name(:type)}='InterventionCosting'"
        execute "UPDATE #{quote_table_name(:attachments)} SET #{quote_column_name(:resource_type)}='InterventionCosts' WHERE #{quote_column_name(:resource_type)}='InterventionCosting'"
        execute "UPDATE #{quote_table_name(:call_messages)} SET #{quote_column_name(:type)}='InterventionCosts' WHERE #{quote_column_name(:type)}='InterventionCosting'"
        execute "UPDATE #{quote_table_name(:calls)} SET #{quote_column_name(:source_type)}='InterventionCosts' WHERE #{quote_column_name(:source_type)}='InterventionCosting'"
        execute "UPDATE #{quote_table_name(:gaps)} SET #{quote_column_name(:type)}='InterventionCosts' WHERE #{quote_column_name(:type)}='InterventionCosting'"
        execute "UPDATE #{quote_table_name(:intervention_parameters)} SET #{quote_column_name(:type)}='InterventionCosts' WHERE #{quote_column_name(:type)}='InterventionCosting'"
        execute "UPDATE #{quote_table_name(:issues)} SET #{quote_column_name(:target_type)}='InterventionCosts' WHERE #{quote_column_name(:target_type)}='InterventionCosting'"
        execute "UPDATE #{quote_table_name(:journal_entries)} SET #{quote_column_name(:resource_type)}='InterventionCosts' WHERE #{quote_column_name(:resource_type)}='InterventionCosting'"
        execute "UPDATE #{quote_table_name(:journal_entry_items)} SET #{quote_column_name(:resource_type)}='InterventionCosts' WHERE #{quote_column_name(:resource_type)}='InterventionCosting'"
        execute "UPDATE #{quote_table_name(:naming_format_fields)} SET #{quote_column_name(:type)}='InterventionCosts' WHERE #{quote_column_name(:type)}='InterventionCosting'"
        execute "UPDATE #{quote_table_name(:naming_formats)} SET #{quote_column_name(:type)}='InterventionCosts' WHERE #{quote_column_name(:type)}='InterventionCosting'"
        execute "UPDATE #{quote_table_name(:notifications)} SET #{quote_column_name(:target_type)}='InterventionCosts' WHERE #{quote_column_name(:target_type)}='InterventionCosting'"
        execute "UPDATE #{quote_table_name(:observations)} SET #{quote_column_name(:subject_type)}='InterventionCosts' WHERE #{quote_column_name(:subject_type)}='InterventionCosting'"
        execute "UPDATE #{quote_table_name(:outgoing_payments)} SET #{quote_column_name(:type)}='InterventionCosts' WHERE #{quote_column_name(:type)}='InterventionCosting'"
        execute "UPDATE #{quote_table_name(:parcel_items)} SET #{quote_column_name(:type)}='InterventionCosts' WHERE #{quote_column_name(:type)}='InterventionCosting'"
        execute "UPDATE #{quote_table_name(:parcels)} SET #{quote_column_name(:type)}='InterventionCosts' WHERE #{quote_column_name(:type)}='InterventionCosting'"
        execute "UPDATE #{quote_table_name(:preferences)} SET #{quote_column_name(:record_value_type)}='InterventionCosts' WHERE #{quote_column_name(:record_value_type)}='InterventionCosting'"
        execute "UPDATE #{quote_table_name(:product_enjoyments)} SET #{quote_column_name(:originator_type)}='InterventionCosts' WHERE #{quote_column_name(:originator_type)}='InterventionCosting'"
        execute "UPDATE #{quote_table_name(:product_linkages)} SET #{quote_column_name(:originator_type)}='InterventionCosts' WHERE #{quote_column_name(:originator_type)}='InterventionCosting'"
        execute "UPDATE #{quote_table_name(:product_links)} SET #{quote_column_name(:originator_type)}='InterventionCosts' WHERE #{quote_column_name(:originator_type)}='InterventionCosting'"
        execute "UPDATE #{quote_table_name(:product_localizations)} SET #{quote_column_name(:originator_type)}='InterventionCosts' WHERE #{quote_column_name(:originator_type)}='InterventionCosting'"
        execute "UPDATE #{quote_table_name(:product_memberships)} SET #{quote_column_name(:originator_type)}='InterventionCosts' WHERE #{quote_column_name(:originator_type)}='InterventionCosting'"
        execute "UPDATE #{quote_table_name(:product_movements)} SET #{quote_column_name(:originator_type)}='InterventionCosts' WHERE #{quote_column_name(:originator_type)}='InterventionCosting'"
        execute "UPDATE #{quote_table_name(:product_ownerships)} SET #{quote_column_name(:originator_type)}='InterventionCosts' WHERE #{quote_column_name(:originator_type)}='InterventionCosting'"
        execute "UPDATE #{quote_table_name(:product_phases)} SET #{quote_column_name(:originator_type)}='InterventionCosts' WHERE #{quote_column_name(:originator_type)}='InterventionCosting'"
        execute "UPDATE #{quote_table_name(:product_readings)} SET #{quote_column_name(:originator_type)}='InterventionCosts' WHERE #{quote_column_name(:originator_type)}='InterventionCosting'"
        execute "UPDATE #{quote_table_name(:products)} SET #{quote_column_name(:type)}='InterventionCosts' WHERE #{quote_column_name(:type)}='InterventionCosting'"
        execute "UPDATE #{quote_table_name(:purchases)} SET #{quote_column_name(:type)}='InterventionCosts' WHERE #{quote_column_name(:type)}='InterventionCosting'"
        execute "UPDATE #{quote_table_name(:synchronization_operations)} SET #{quote_column_name(:originator_type)}='InterventionCosts' WHERE #{quote_column_name(:originator_type)}='InterventionCosting'"
        execute "UPDATE #{quote_table_name(:versions)} SET #{quote_column_name(:item_type)}='InterventionCosts' WHERE #{quote_column_name(:item_type)}='InterventionCosting'"
      end
    end
    # Custom fields
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:custom_fields)} SET #{quote_column_name(:customized_type)}='InterventionCosting' WHERE #{quote_column_name(:customized_type)}='InterventionCosts'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:custom_fields)} SET #{quote_column_name(:customized_type)}='InterventionCosts' WHERE #{quote_column_name(:customized_type)}='InterventionCosting'"
      end
    end
    # Listings
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:listings)} SET #{quote_column_name(:root_model)}='intervention_costing' WHERE #{quote_column_name(:root_model)}='intervention_costs'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:listings)} SET #{quote_column_name(:root_model)}='intervention_costs' WHERE #{quote_column_name(:root_model)}='intervention_costing'"
      end
    end
    # Sequences
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:sequences)} SET #{quote_column_name(:usage)}='intervention_costings' WHERE #{quote_column_name(:usage)}='intervention_costs'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:sequences)} SET #{quote_column_name(:usage)}='intervention_costs' WHERE #{quote_column_name(:usage)}='intervention_costings'"
      end
    end

    rename_column :interventions, :intervention_costs_id, :costing_id
  end
end
