class NormalizeEntityTypes < ActiveRecord::Migration
  NATURES = {
    entity: :entity,
    contact: :contact,
    organization: :organization,
    company: :organization,
    civil_society: :organization,
    economic_interest_group: :organization,
    cooperative: :organization,
    association: :organization,
    syndicate: :organization,
    foundation: :organization,
    collectivity: :organization,
    public_establishment: :organization,
    public_interest_group: :organization,
    sir: :contact,
    sir_and_madam: :contact,
    madam: :contact,
    professor: :contact,
    doctor: :contact
  }

  TITLES = {
    sir: "M.",
    sir_and_madam: "Mme M.",
    madam: "Mme",
    professor: "Pr",
    doctor: "Dr"
  }

  def up
    # Add title column
    add_column :entities, :title, :string
    execute "UPDATE entities SET title = CASE " + TITLES.map { |nature, title| "WHEN nature = '#{nature}' THEN '#{title}'" }.join(" ") + " END"

    # execute "UPDATE #{quote_table_name(:affairs)} SET #{quote_column_name(:type)}='Entity' WHERE #{quote_column_name(:type)} IN ('Contact', 'Organization')"
    execute "UPDATE #{quote_table_name(:attachments)} SET #{quote_column_name(:resource_type)}='Entity' WHERE #{quote_column_name(:resource_type)} IN ('Contact', 'Organization')"
    # execute "UPDATE #{quote_table_name(:entities)} SET #{quote_column_name(:type)}='Entity' WHERE #{quote_column_name(:type)} IN ('Contact', 'Organization')"
    execute "UPDATE #{quote_table_name(:interventions)} SET #{quote_column_name(:ressource_type)}='Entity' WHERE #{quote_column_name(:ressource_type)} IN ('Contact', 'Organization')"
    execute "UPDATE #{quote_table_name(:issues)} SET #{quote_column_name(:target_type)}='Entity' WHERE #{quote_column_name(:target_type)} IN ('Contact', 'Organization')"
    execute "UPDATE #{quote_table_name(:journal_entries)} SET #{quote_column_name(:resource_type)}='Entity' WHERE #{quote_column_name(:resource_type)} IN ('Contact', 'Organization')"
    execute "UPDATE #{quote_table_name(:observations)} SET #{quote_column_name(:subject_type)}='Entity' WHERE #{quote_column_name(:subject_type)} IN ('Contact', 'Organization')"
    execute "UPDATE #{quote_table_name(:preferences)} SET #{quote_column_name(:record_value_type)}='Entity' WHERE #{quote_column_name(:record_value_type)} IN ('Contact', 'Organization')"
    execute "UPDATE #{quote_table_name(:product_enjoyments)} SET #{quote_column_name(:originator_type)}='Entity' WHERE #{quote_column_name(:originator_type)} IN ('Contact', 'Organization')"
    execute "UPDATE #{quote_table_name(:product_junctions)} SET #{quote_column_name(:originator_type)}='Entity' WHERE #{quote_column_name(:originator_type)} IN ('Contact', 'Organization')"
    # execute "UPDATE #{quote_table_name(:product_junctions)} SET #{quote_column_name(:type)}='Entity' WHERE #{quote_column_name(:type)} IN ('Contact', 'Organization')"
    execute "UPDATE #{quote_table_name(:product_linkages)} SET #{quote_column_name(:originator_type)}='Entity' WHERE #{quote_column_name(:originator_type)} IN ('Contact', 'Organization')"
    execute "UPDATE #{quote_table_name(:product_links)} SET #{quote_column_name(:originator_type)}='Entity' WHERE #{quote_column_name(:originator_type)} IN ('Contact', 'Organization')"
    execute "UPDATE #{quote_table_name(:product_localizations)} SET #{quote_column_name(:originator_type)}='Entity' WHERE #{quote_column_name(:originator_type)} IN ('Contact', 'Organization')"
    execute "UPDATE #{quote_table_name(:product_memberships)} SET #{quote_column_name(:originator_type)}='Entity' WHERE #{quote_column_name(:originator_type)} IN ('Contact', 'Organization')"
    execute "UPDATE #{quote_table_name(:product_ownerships)} SET #{quote_column_name(:originator_type)}='Entity' WHERE #{quote_column_name(:originator_type)} IN ('Contact', 'Organization')"
    execute "UPDATE #{quote_table_name(:product_phases)} SET #{quote_column_name(:originator_type)}='Entity' WHERE #{quote_column_name(:originator_type)} IN ('Contact', 'Organization')"
    execute "UPDATE #{quote_table_name(:product_reading_tasks)} SET #{quote_column_name(:originator_type)}='Entity' WHERE #{quote_column_name(:originator_type)} IN ('Contact', 'Organization')"
    execute "UPDATE #{quote_table_name(:product_readings)} SET #{quote_column_name(:originator_type)}='Entity' WHERE #{quote_column_name(:originator_type)} IN ('Contact', 'Organization')"
    # execute "UPDATE #{quote_table_name(:products)} SET #{quote_column_name(:type)}='Entity' WHERE #{quote_column_name(:type)} IN ('Contact', 'Organization')"
    # execute "UPDATE #{quote_table_name(:sale_items)} SET #{quote_column_name(:type)}='Entity' WHERE #{quote_column_name(:type)} IN ('Contact', 'Organization')"
    # execute "UPDATE #{quote_table_name(:sales)} SET #{quote_column_name(:type)}='Entity' WHERE #{quote_column_name(:type)} IN ('Contact', 'Organization')"
    execute "UPDATE #{quote_table_name(:versions)} SET #{quote_column_name(:item_type)}='Entity' WHERE #{quote_column_name(:item_type)} IN ('Contact', 'Organization')"

    # Remove type column
    execute "UPDATE entities SET nature = CASE " + NATURES.map { |old_nature, new_nature| "WHEN nature = '#{old_nature}' THEN '#{new_nature == :entity ? :organization : new_nature}'" }.join(" ") + " ELSE 'organization' END"
    remove_column :entities, :type, :string
  end

  def down
    # Add type column
    add_column :entities, :type, :string
    execute "UPDATE entities SET type = CASE WHEN nature = 'contact' THEN 'Contact' ELSE 'Organization' END"

    # execute "UPDATE #{quote_table_name(:affairs)} SET #{quote_column_name(:type)} = ex.type FROM entities AS ex WHERE ex.id = resource_id AND  #{quote_column_name(:type)} = 'Entity'"
    execute "UPDATE #{quote_table_name(:attachments)} SET #{quote_column_name(:resource_type)} = ex.type FROM entities AS ex WHERE ex.id = resource_id AND  #{quote_column_name(:resource_type)} = 'Entity'"
    # execute "UPDATE #{quote_table_name(:entities)} SET #{quote_column_name(:type)} = ex.type FROM entities AS ex WHERE ex.id = resource_id AND  #{quote_column_name(:type)} = 'Entity'"
    execute "UPDATE #{quote_table_name(:interventions)} SET #{quote_column_name(:ressource_type)} = ex.type FROM entities AS ex WHERE ex.id = ressource_id AND  #{quote_column_name(:ressource_type)} = 'Entity'"
    execute "UPDATE #{quote_table_name(:issues)} SET #{quote_column_name(:target_type)} = ex.type FROM entities AS ex WHERE ex.id = target_id AND  #{quote_column_name(:target_type)} = 'Entity'"
    execute "UPDATE #{quote_table_name(:journal_entries)} SET #{quote_column_name(:resource_type)} = ex.type FROM entities AS ex WHERE ex.id = resource_id AND  #{quote_column_name(:resource_type)} = 'Entity'"
    execute "UPDATE #{quote_table_name(:observations)} SET #{quote_column_name(:subject_type)} = ex.type FROM entities AS ex WHERE ex.id = subject_id AND  #{quote_column_name(:subject_type)} = 'Entity'"
    execute "UPDATE #{quote_table_name(:preferences)} SET #{quote_column_name(:record_value_type)} = ex.type FROM entities AS ex WHERE ex.id = record_value_id AND  #{quote_column_name(:record_value_type)} = 'Entity'"
    execute "UPDATE #{quote_table_name(:product_enjoyments)} SET #{quote_column_name(:originator_type)} = ex.type FROM entities AS ex WHERE ex.id = originator_id AND  #{quote_column_name(:originator_type)} = 'Entity'"
    execute "UPDATE #{quote_table_name(:product_junctions)} SET #{quote_column_name(:originator_type)} = ex.type FROM entities AS ex WHERE ex.id = originator_id AND  #{quote_column_name(:originator_type)} = 'Entity'"
    # execute "UPDATE #{quote_table_name(:product_junctions)} SET #{quote_column_name(:type)} = ex.type FROM entities AS ex WHERE ex.id = resource_id AND  #{quote_column_name(:type)} = 'Entity'"
    execute "UPDATE #{quote_table_name(:product_linkages)} SET #{quote_column_name(:originator_type)} = ex.type FROM entities AS ex WHERE ex.id = originator_id AND  #{quote_column_name(:originator_type)} = 'Entity'"
    execute "UPDATE #{quote_table_name(:product_links)} SET #{quote_column_name(:originator_type)} = ex.type FROM entities AS ex WHERE ex.id = originator_id AND  #{quote_column_name(:originator_type)} = 'Entity'"
    execute "UPDATE #{quote_table_name(:product_localizations)} SET #{quote_column_name(:originator_type)} = ex.type FROM entities AS ex WHERE ex.id = originator_id AND  #{quote_column_name(:originator_type)} = 'Entity'"
    execute "UPDATE #{quote_table_name(:product_memberships)} SET #{quote_column_name(:originator_type)} = ex.type FROM entities AS ex WHERE ex.id = originator_id AND  #{quote_column_name(:originator_type)} = 'Entity'"
    execute "UPDATE #{quote_table_name(:product_ownerships)} SET #{quote_column_name(:originator_type)} = ex.type FROM entities AS ex WHERE ex.id = originator_id AND  #{quote_column_name(:originator_type)} = 'Entity'"
    execute "UPDATE #{quote_table_name(:product_phases)} SET #{quote_column_name(:originator_type)} = ex.type FROM entities AS ex WHERE ex.id = originator_id AND  #{quote_column_name(:originator_type)} = 'Entity'"
    execute "UPDATE #{quote_table_name(:product_reading_tasks)} SET #{quote_column_name(:originator_type)} = ex.type FROM entities AS ex WHERE ex.id = originator_id AND  #{quote_column_name(:originator_type)} = 'Entity'"
    execute "UPDATE #{quote_table_name(:product_readings)} SET #{quote_column_name(:originator_type)} = ex.type FROM entities AS ex WHERE ex.id = originator_id AND  #{quote_column_name(:originator_type)} = 'Entity'"
    # execute "UPDATE #{quote_table_name(:products)} SET #{quote_column_name(:type)} = ex.type FROM entities AS ex WHERE ex.id = resource_id AND  #{quote_column_name(:type)} = 'Entity'"
    # execute "UPDATE #{quote_table_name(:sale_items)} SET #{quote_column_name(:type)} = ex.type FROM entities AS ex WHERE ex.id = resource_id AND  #{quote_column_name(:type)} = 'Entity'"
    # execute "UPDATE #{quote_table_name(:sales)} SET #{quote_column_name(:type)} = ex.type FROM entities AS ex WHERE ex.id = resource_id AND  #{quote_column_name(:type)} = 'Entity'"
    execute "UPDATE #{quote_table_name(:versions)} SET #{quote_column_name(:item_type)} = ex.type FROM entities AS ex WHERE ex.id = item_id AND  #{quote_column_name(:item_type)} = 'Entity'"


    # Remove title column
    remove_column :entities, :title
  end

end
