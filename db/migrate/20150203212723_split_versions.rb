class SplitVersions < ActiveRecord::Migration
  def change
    create_table :entity_versions do |t|
      t.string   :event,        null: false
      t.integer  :item_id
      t.text     :item_object
      t.text     :item_changes
      t.datetime :created_at,   null: false
      t.integer  :creator_id
      t.string   :creator_name
    end

    reversible do |dir|
      dir.up do
        execute "INSERT INTO entity_versions(event, item_id, item_object, item_changes, created_at, creator_id, creator_name) SELECT event, item_id, item_object, item_changes, created_at, creator_id, creator_name FROM versions WHERE item_type IN ('Entity', 'LegalEntity', 'Person')"
      end
      dir.down do
        execute "INSERT INTO versions(event, item_id, item_type, item_object, item_changes, created_at, creator_id, creator_name) SELECT event, item_id, 'Entity', item_object, item_changes, created_at, creator_id, creator_name FROM entity_versions"
      end
    end

    create_table :issue_versions do |t|
      t.string   :event,        null: false
      t.integer  :item_id
      t.text     :item_object
      t.text     :item_changes
      t.datetime :created_at,   null: false
      t.integer  :creator_id
      t.string   :creator_name
    end

    reversible do |dir|
      dir.up do
        execute "INSERT INTO issue_versions(event, item_id, item_object, item_changes, created_at, creator_id, creator_name) SELECT event, item_id, item_object, item_changes, created_at, creator_id, creator_name FROM versions WHERE item_type = 'Issue'"
      end
      dir.down do
        execute "INSERT INTO versions(event, item_id, item_type, item_object, item_changes, created_at, creator_id, creator_name) SELECT event, item_id, 'Issue', item_object, item_changes, created_at, creator_id, creator_name FROM issue_versions"
      end
    end


    rename_table :versions, :product_versions

    reversible do |dir|
      dir.up do
        remove_column :product_versions, :item_type
      end
      dir.down do
        add_column :product_versions, :item_type, :string
        execute "UPDATE product_versions SET item_type = 'Product'"
      end
    end

  end
end
