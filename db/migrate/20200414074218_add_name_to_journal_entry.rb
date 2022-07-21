class AddNameToJournalEntry < ActiveRecord::Migration[4.2]
  def change
    reversible do |dir|
      dir.up do
        add_column :journal_entries, :name, :string

        execute <<-SQL
          UPDATE journal_entries
          SET name = item_infos.name
          FROM (SELECT jei.name, jei.entry_id
                FROM journal_entry_items jei
                INNER JOIN (SELECT MIN(id) as id
                            FROM journal_entry_items
                            GROUP BY entry_id) first_item_id
                            ON jei.id = first_item_id.id) item_infos
                WHERE id = item_infos.entry_id
        SQL
      end

      dir.down do
        remove_column :journal_entries, :name
      end
    end
  end
end
