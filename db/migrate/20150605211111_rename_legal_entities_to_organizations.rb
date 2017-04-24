class RenameLegalEntitiesToOrganizations < ActiveRecord::Migration
  def change
    # Polymorphic columns
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:affairs)} SET #{quote_column_name(:type)}='Organization' WHERE #{quote_column_name(:type)}='LegalEntity'"
        execute "UPDATE #{quote_table_name(:attachments)} SET #{quote_column_name(:resource_type)}='Organization' WHERE #{quote_column_name(:resource_type)}='LegalEntity'"
        execute "UPDATE #{quote_table_name(:entities)} SET #{quote_column_name(:type)}='Organization' WHERE #{quote_column_name(:type)}='LegalEntity'"
        execute "UPDATE #{quote_table_name(:interventions)} SET #{quote_column_name(:ressource_type)}='Organization' WHERE #{quote_column_name(:ressource_type)}='LegalEntity'"
        execute "UPDATE #{quote_table_name(:issues)} SET #{quote_column_name(:target_type)}='Organization' WHERE #{quote_column_name(:target_type)}='LegalEntity'"
        execute "UPDATE #{quote_table_name(:journal_entries)} SET #{quote_column_name(:resource_type)}='Organization' WHERE #{quote_column_name(:resource_type)}='LegalEntity'"
        execute "UPDATE #{quote_table_name(:observations)} SET #{quote_column_name(:subject_type)}='Organization' WHERE #{quote_column_name(:subject_type)}='LegalEntity'"
        execute "UPDATE #{quote_table_name(:preferences)} SET #{quote_column_name(:record_value_type)}='Organization' WHERE #{quote_column_name(:record_value_type)}='LegalEntity'"
        execute "UPDATE #{quote_table_name(:product_enjoyments)} SET #{quote_column_name(:originator_type)}='Organization' WHERE #{quote_column_name(:originator_type)}='LegalEntity'"
        execute "UPDATE #{quote_table_name(:product_junctions)} SET #{quote_column_name(:originator_type)}='Organization' WHERE #{quote_column_name(:originator_type)}='LegalEntity'"
        execute "UPDATE #{quote_table_name(:product_junctions)} SET #{quote_column_name(:type)}='Organization' WHERE #{quote_column_name(:type)}='LegalEntity'"
        execute "UPDATE #{quote_table_name(:product_linkages)} SET #{quote_column_name(:originator_type)}='Organization' WHERE #{quote_column_name(:originator_type)}='LegalEntity'"
        execute "UPDATE #{quote_table_name(:product_links)} SET #{quote_column_name(:originator_type)}='Organization' WHERE #{quote_column_name(:originator_type)}='LegalEntity'"
        execute "UPDATE #{quote_table_name(:product_localizations)} SET #{quote_column_name(:originator_type)}='Organization' WHERE #{quote_column_name(:originator_type)}='LegalEntity'"
        execute "UPDATE #{quote_table_name(:product_memberships)} SET #{quote_column_name(:originator_type)}='Organization' WHERE #{quote_column_name(:originator_type)}='LegalEntity'"
        execute "UPDATE #{quote_table_name(:product_ownerships)} SET #{quote_column_name(:originator_type)}='Organization' WHERE #{quote_column_name(:originator_type)}='LegalEntity'"
        execute "UPDATE #{quote_table_name(:product_phases)} SET #{quote_column_name(:originator_type)}='Organization' WHERE #{quote_column_name(:originator_type)}='LegalEntity'"
        execute "UPDATE #{quote_table_name(:product_reading_tasks)} SET #{quote_column_name(:originator_type)}='Organization' WHERE #{quote_column_name(:originator_type)}='LegalEntity'"
        execute "UPDATE #{quote_table_name(:product_readings)} SET #{quote_column_name(:originator_type)}='Organization' WHERE #{quote_column_name(:originator_type)}='LegalEntity'"
        execute "UPDATE #{quote_table_name(:products)} SET #{quote_column_name(:type)}='Organization' WHERE #{quote_column_name(:type)}='LegalEntity'"
        execute "UPDATE #{quote_table_name(:sale_items)} SET #{quote_column_name(:type)}='Organization' WHERE #{quote_column_name(:type)}='LegalEntity'"
        execute "UPDATE #{quote_table_name(:sales)} SET #{quote_column_name(:type)}='Organization' WHERE #{quote_column_name(:type)}='LegalEntity'"
        execute "UPDATE #{quote_table_name(:versions)} SET #{quote_column_name(:item_type)}='Organization' WHERE #{quote_column_name(:item_type)}='LegalEntity'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:affairs)} SET #{quote_column_name(:type)}='LegalEntity' WHERE #{quote_column_name(:type)}='Organization'"
        execute "UPDATE #{quote_table_name(:attachments)} SET #{quote_column_name(:resource_type)}='LegalEntity' WHERE #{quote_column_name(:resource_type)}='Organization'"
        execute "UPDATE #{quote_table_name(:entities)} SET #{quote_column_name(:type)}='LegalEntity' WHERE #{quote_column_name(:type)}='Organization'"
        execute "UPDATE #{quote_table_name(:interventions)} SET #{quote_column_name(:ressource_type)}='LegalEntity' WHERE #{quote_column_name(:ressource_type)}='Organization'"
        execute "UPDATE #{quote_table_name(:issues)} SET #{quote_column_name(:target_type)}='LegalEntity' WHERE #{quote_column_name(:target_type)}='Organization'"
        execute "UPDATE #{quote_table_name(:journal_entries)} SET #{quote_column_name(:resource_type)}='LegalEntity' WHERE #{quote_column_name(:resource_type)}='Organization'"
        execute "UPDATE #{quote_table_name(:observations)} SET #{quote_column_name(:subject_type)}='LegalEntity' WHERE #{quote_column_name(:subject_type)}='Organization'"
        execute "UPDATE #{quote_table_name(:preferences)} SET #{quote_column_name(:record_value_type)}='LegalEntity' WHERE #{quote_column_name(:record_value_type)}='Organization'"
        execute "UPDATE #{quote_table_name(:product_enjoyments)} SET #{quote_column_name(:originator_type)}='LegalEntity' WHERE #{quote_column_name(:originator_type)}='Organization'"
        execute "UPDATE #{quote_table_name(:product_junctions)} SET #{quote_column_name(:originator_type)}='LegalEntity' WHERE #{quote_column_name(:originator_type)}='Organization'"
        execute "UPDATE #{quote_table_name(:product_junctions)} SET #{quote_column_name(:type)}='LegalEntity' WHERE #{quote_column_name(:type)}='Organization'"
        execute "UPDATE #{quote_table_name(:product_linkages)} SET #{quote_column_name(:originator_type)}='LegalEntity' WHERE #{quote_column_name(:originator_type)}='Organization'"
        execute "UPDATE #{quote_table_name(:product_links)} SET #{quote_column_name(:originator_type)}='LegalEntity' WHERE #{quote_column_name(:originator_type)}='Organization'"
        execute "UPDATE #{quote_table_name(:product_localizations)} SET #{quote_column_name(:originator_type)}='LegalEntity' WHERE #{quote_column_name(:originator_type)}='Organization'"
        execute "UPDATE #{quote_table_name(:product_memberships)} SET #{quote_column_name(:originator_type)}='LegalEntity' WHERE #{quote_column_name(:originator_type)}='Organization'"
        execute "UPDATE #{quote_table_name(:product_ownerships)} SET #{quote_column_name(:originator_type)}='LegalEntity' WHERE #{quote_column_name(:originator_type)}='Organization'"
        execute "UPDATE #{quote_table_name(:product_phases)} SET #{quote_column_name(:originator_type)}='LegalEntity' WHERE #{quote_column_name(:originator_type)}='Organization'"
        execute "UPDATE #{quote_table_name(:product_reading_tasks)} SET #{quote_column_name(:originator_type)}='LegalEntity' WHERE #{quote_column_name(:originator_type)}='Organization'"
        execute "UPDATE #{quote_table_name(:product_readings)} SET #{quote_column_name(:originator_type)}='LegalEntity' WHERE #{quote_column_name(:originator_type)}='Organization'"
        execute "UPDATE #{quote_table_name(:products)} SET #{quote_column_name(:type)}='LegalEntity' WHERE #{quote_column_name(:type)}='Organization'"
        execute "UPDATE #{quote_table_name(:sale_items)} SET #{quote_column_name(:type)}='LegalEntity' WHERE #{quote_column_name(:type)}='Organization'"
        execute "UPDATE #{quote_table_name(:sales)} SET #{quote_column_name(:type)}='LegalEntity' WHERE #{quote_column_name(:type)}='Organization'"
        execute "UPDATE #{quote_table_name(:versions)} SET #{quote_column_name(:item_type)}='LegalEntity' WHERE #{quote_column_name(:item_type)}='Organization'"
      end
    end
    # Custom fields
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:custom_fields)} SET #{quote_column_name(:customized_type)}='Organization' WHERE #{quote_column_name(:customized_type)}='LegalEntity'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:custom_fields)} SET #{quote_column_name(:customized_type)}='LegalEntity' WHERE #{quote_column_name(:customized_type)}='Organization'"
      end
    end
    # Listings
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:listings)} SET #{quote_column_name(:root_model)}='organization' WHERE #{quote_column_name(:root_model)}='legal_entity'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:listings)} SET #{quote_column_name(:root_model)}='legal_entity' WHERE #{quote_column_name(:root_model)}='organization'"
      end
    end
    # Sequences
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:sequences)} SET #{quote_column_name(:usage)}='organizations' WHERE #{quote_column_name(:usage)}='legal_entities'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:sequences)} SET #{quote_column_name(:usage)}='legal_entities' WHERE #{quote_column_name(:usage)}='organizations'"
      end
    end
    # Entities
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:entities)} SET #{quote_column_name(:nature)}='organization' WHERE #{quote_column_name(:nature)}='legal_entity'"
        %i[users roles].each do |table|
          execute "UPDATE #{quote_table_name(table)} SET #{quote_column_name(:rights)}=REPLACE(rights, 'legal_entities', 'organizations')"
        end
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:entities)} SET #{quote_column_name(:nature)}='legal_entity' WHERE #{quote_column_name(:nature)}='organization'"
        %i[users roles].each do |table|
          execute "UPDATE #{quote_table_name(table)} SET #{quote_column_name(:rights)}=REPLACE(rights, 'organizations', 'legal_entities')"
        end
      end
    end
  end
end
