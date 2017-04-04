class NormalizeEntityLinks < ActiveRecord::Migration
  def change
    rename_column :entity_links, :entity_1_id,   :entity_id
    rename_column :entity_links, :entity_1_role, :entity_role
    rename_column :entity_links, :entity_2_id,   :linked_id
    rename_column :entity_links, :entity_2_role, :linked_role

    add_column :entity_links, :post, :string

    reversible do |dir|
      dir.up do
        execute "UPDATE entity_links SET nature = 'membership' WHERE nature IN ('cooperation', 'association', 'work')"
        %w[entity linked].each do |type|
          execute "UPDATE entity_links SET #{type}_role = 'organization' WHERE #{type}_role IN ('employer', 'cooperative', 'association') AND nature = 'membership'"
          execute "UPDATE entity_links SET #{type}_role = 'member' WHERE #{type}_role IN ('member', 'employee') AND nature = 'membership'"
        end

        execute "UPDATE entity_links SET nature = 'hierarchy' WHERE nature = 'management'"

        execute "UPDATE entities SET full_name = TRIM(COALESCE(title || ' ', '') || COALESCE(first_name ||' ', '') || COALESCE(last_name, ''))"
      end
      dir.down do
        execute "UPDATE entities SET full_name = TRIM(COALESCE(title || ' ', '') || COALESCE(last_name ||' ', '') || COALESCE(first_name, ''))"

        execute "UPDATE entity_links SET nature = 'management' WHERE nature = 'hierarchy'"

        %w[entity linked].each do |type|
          execute "UPDATE entity_links SET #{type}_role = 'employer' WHERE #{type}_role = 'organization' AND nature = 'membership'"
          execute "UPDATE entity_links SET #{type}_role = 'employee' WHERE #{type}_role = 'member' AND nature = 'membership'"
        end
        execute "UPDATE entity_links SET nature = 'work' WHERE nature = 'membership'"
      end
    end

    add_column :entity_links, :main, :boolean, null: false, default: false

    reversible do |dir|
      dir.up do
        execute 'UPDATE entity_links SET main = TRUE FROM (SELECT el.id, ROW_NUMBER() OVER (PARTITION BY el.entity_id ORDER BY el.id DESC) AS rank FROM entity_links AS el) AS l WHERE l.rank = 1'
      end
    end
  end
end
