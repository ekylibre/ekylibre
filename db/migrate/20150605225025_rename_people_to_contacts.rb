class RenamePeopleToContacts < ActiveRecord::Migration
  def change
    # Polymorphic columns
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:affairs)} SET #{quote_column_name(:type)}='Contact' WHERE #{quote_column_name(:type)}='Person'"
        execute "UPDATE #{quote_table_name(:attachments)} SET #{quote_column_name(:resource_type)}='Contact' WHERE #{quote_column_name(:resource_type)}='Person'"
        execute "UPDATE #{quote_table_name(:entities)} SET #{quote_column_name(:type)}='Contact' WHERE #{quote_column_name(:type)}='Person'"
        execute "UPDATE #{quote_table_name(:interventions)} SET #{quote_column_name(:ressource_type)}='Contact' WHERE #{quote_column_name(:ressource_type)}='Person'"
        execute "UPDATE #{quote_table_name(:issues)} SET #{quote_column_name(:target_type)}='Contact' WHERE #{quote_column_name(:target_type)}='Person'"
        execute "UPDATE #{quote_table_name(:journal_entries)} SET #{quote_column_name(:resource_type)}='Contact' WHERE #{quote_column_name(:resource_type)}='Person'"
        execute "UPDATE #{quote_table_name(:observations)} SET #{quote_column_name(:subject_type)}='Contact' WHERE #{quote_column_name(:subject_type)}='Person'"
        execute "UPDATE #{quote_table_name(:preferences)} SET #{quote_column_name(:record_value_type)}='Contact' WHERE #{quote_column_name(:record_value_type)}='Person'"
        execute "UPDATE #{quote_table_name(:product_enjoyments)} SET #{quote_column_name(:originator_type)}='Contact' WHERE #{quote_column_name(:originator_type)}='Person'"
        execute "UPDATE #{quote_table_name(:product_junctions)} SET #{quote_column_name(:originator_type)}='Contact' WHERE #{quote_column_name(:originator_type)}='Person'"
        execute "UPDATE #{quote_table_name(:product_junctions)} SET #{quote_column_name(:type)}='Contact' WHERE #{quote_column_name(:type)}='Person'"
        execute "UPDATE #{quote_table_name(:product_linkages)} SET #{quote_column_name(:originator_type)}='Contact' WHERE #{quote_column_name(:originator_type)}='Person'"
        execute "UPDATE #{quote_table_name(:product_links)} SET #{quote_column_name(:originator_type)}='Contact' WHERE #{quote_column_name(:originator_type)}='Person'"
        execute "UPDATE #{quote_table_name(:product_localizations)} SET #{quote_column_name(:originator_type)}='Contact' WHERE #{quote_column_name(:originator_type)}='Person'"
        execute "UPDATE #{quote_table_name(:product_memberships)} SET #{quote_column_name(:originator_type)}='Contact' WHERE #{quote_column_name(:originator_type)}='Person'"
        execute "UPDATE #{quote_table_name(:product_ownerships)} SET #{quote_column_name(:originator_type)}='Contact' WHERE #{quote_column_name(:originator_type)}='Person'"
        execute "UPDATE #{quote_table_name(:product_phases)} SET #{quote_column_name(:originator_type)}='Contact' WHERE #{quote_column_name(:originator_type)}='Person'"
        execute "UPDATE #{quote_table_name(:product_reading_tasks)} SET #{quote_column_name(:originator_type)}='Contact' WHERE #{quote_column_name(:originator_type)}='Person'"
        execute "UPDATE #{quote_table_name(:product_readings)} SET #{quote_column_name(:originator_type)}='Contact' WHERE #{quote_column_name(:originator_type)}='Person'"
        execute "UPDATE #{quote_table_name(:products)} SET #{quote_column_name(:type)}='Contact' WHERE #{quote_column_name(:type)}='Person'"
        execute "UPDATE #{quote_table_name(:sale_items)} SET #{quote_column_name(:type)}='Contact' WHERE #{quote_column_name(:type)}='Person'"
        execute "UPDATE #{quote_table_name(:sales)} SET #{quote_column_name(:type)}='Contact' WHERE #{quote_column_name(:type)}='Person'"
        execute "UPDATE #{quote_table_name(:versions)} SET #{quote_column_name(:item_type)}='Contact' WHERE #{quote_column_name(:item_type)}='Person'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:affairs)} SET #{quote_column_name(:type)}='Person' WHERE #{quote_column_name(:type)}='Contact'"
        execute "UPDATE #{quote_table_name(:attachments)} SET #{quote_column_name(:resource_type)}='Person' WHERE #{quote_column_name(:resource_type)}='Contact'"
        execute "UPDATE #{quote_table_name(:entities)} SET #{quote_column_name(:type)}='Person' WHERE #{quote_column_name(:type)}='Contact'"
        execute "UPDATE #{quote_table_name(:interventions)} SET #{quote_column_name(:ressource_type)}='Person' WHERE #{quote_column_name(:ressource_type)}='Contact'"
        execute "UPDATE #{quote_table_name(:issues)} SET #{quote_column_name(:target_type)}='Person' WHERE #{quote_column_name(:target_type)}='Contact'"
        execute "UPDATE #{quote_table_name(:journal_entries)} SET #{quote_column_name(:resource_type)}='Person' WHERE #{quote_column_name(:resource_type)}='Contact'"
        execute "UPDATE #{quote_table_name(:observations)} SET #{quote_column_name(:subject_type)}='Person' WHERE #{quote_column_name(:subject_type)}='Contact'"
        execute "UPDATE #{quote_table_name(:preferences)} SET #{quote_column_name(:record_value_type)}='Person' WHERE #{quote_column_name(:record_value_type)}='Contact'"
        execute "UPDATE #{quote_table_name(:product_enjoyments)} SET #{quote_column_name(:originator_type)}='Person' WHERE #{quote_column_name(:originator_type)}='Contact'"
        execute "UPDATE #{quote_table_name(:product_junctions)} SET #{quote_column_name(:originator_type)}='Person' WHERE #{quote_column_name(:originator_type)}='Contact'"
        execute "UPDATE #{quote_table_name(:product_junctions)} SET #{quote_column_name(:type)}='Person' WHERE #{quote_column_name(:type)}='Contact'"
        execute "UPDATE #{quote_table_name(:product_linkages)} SET #{quote_column_name(:originator_type)}='Person' WHERE #{quote_column_name(:originator_type)}='Contact'"
        execute "UPDATE #{quote_table_name(:product_links)} SET #{quote_column_name(:originator_type)}='Person' WHERE #{quote_column_name(:originator_type)}='Contact'"
        execute "UPDATE #{quote_table_name(:product_localizations)} SET #{quote_column_name(:originator_type)}='Person' WHERE #{quote_column_name(:originator_type)}='Contact'"
        execute "UPDATE #{quote_table_name(:product_memberships)} SET #{quote_column_name(:originator_type)}='Person' WHERE #{quote_column_name(:originator_type)}='Contact'"
        execute "UPDATE #{quote_table_name(:product_ownerships)} SET #{quote_column_name(:originator_type)}='Person' WHERE #{quote_column_name(:originator_type)}='Contact'"
        execute "UPDATE #{quote_table_name(:product_phases)} SET #{quote_column_name(:originator_type)}='Person' WHERE #{quote_column_name(:originator_type)}='Contact'"
        execute "UPDATE #{quote_table_name(:product_reading_tasks)} SET #{quote_column_name(:originator_type)}='Person' WHERE #{quote_column_name(:originator_type)}='Contact'"
        execute "UPDATE #{quote_table_name(:product_readings)} SET #{quote_column_name(:originator_type)}='Person' WHERE #{quote_column_name(:originator_type)}='Contact'"
        execute "UPDATE #{quote_table_name(:products)} SET #{quote_column_name(:type)}='Person' WHERE #{quote_column_name(:type)}='Contact'"
        execute "UPDATE #{quote_table_name(:sale_items)} SET #{quote_column_name(:type)}='Person' WHERE #{quote_column_name(:type)}='Contact'"
        execute "UPDATE #{quote_table_name(:sales)} SET #{quote_column_name(:type)}='Person' WHERE #{quote_column_name(:type)}='Contact'"
        execute "UPDATE #{quote_table_name(:versions)} SET #{quote_column_name(:item_type)}='Person' WHERE #{quote_column_name(:item_type)}='Contact'"
      end
    end
    # Custom fields
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:custom_fields)} SET #{quote_column_name(:customized_type)}='Contact' WHERE #{quote_column_name(:customized_type)}='Person'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:custom_fields)} SET #{quote_column_name(:customized_type)}='Person' WHERE #{quote_column_name(:customized_type)}='Contact'"
      end
    end
    # Listings
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:listings)} SET #{quote_column_name(:root_model)}='contact' WHERE #{quote_column_name(:root_model)}='person'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:listings)} SET #{quote_column_name(:root_model)}='person' WHERE #{quote_column_name(:root_model)}='contact'"
      end
    end
    # Sequences
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:sequences)} SET #{quote_column_name(:usage)}='contacts' WHERE #{quote_column_name(:usage)}='people'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:sequences)} SET #{quote_column_name(:usage)}='people' WHERE #{quote_column_name(:usage)}='contacts'"
      end
    end
    # Entities
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:entities)} SET #{quote_column_name(:nature)}='contact' WHERE #{quote_column_name(:nature)}='person'"
        %i[users roles].each do |table|
          execute "UPDATE #{quote_table_name(table)} SET #{quote_column_name(:rights)}=REPLACE(rights, 'people', 'contacts')"
        end
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:entities)} SET #{quote_column_name(:nature)}='person' WHERE #{quote_column_name(:nature)}='contact'"
        %i[users roles].each do |table|
          execute "UPDATE #{quote_table_name(table)} SET #{quote_column_name(:rights)}=REPLACE(rights, 'contacts', 'people')"
        end
      end
    end
  end
end
