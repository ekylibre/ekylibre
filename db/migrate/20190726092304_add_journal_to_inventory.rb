class AddJournalToInventory < ActiveRecord::Migration[4.2]
  def change
    add_reference :inventories, :journal, foreign_key: true

    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE inventories
          SET journal_id = (
            SELECT j.id
            FROM journals j
            WHERE j.nature = 'various'
              AND j.used_for_permanent_stock_inventory = 't'
          )
        SQL
      end
    end
  end
end
