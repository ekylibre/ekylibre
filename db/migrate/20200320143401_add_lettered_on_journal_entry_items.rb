class AddLetteredOnJournalEntryItems < ActiveRecord::Migration[4.2]
  def change
    add_column :journal_entry_items, :lettered_at, :datetime, index: true
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE journal_entry_items
          SET lettered_at = updated_at
          WHERE letter IS NOT NULL AND letter NOT LIKE '%*'
        SQL
      end
    end
  end
end
