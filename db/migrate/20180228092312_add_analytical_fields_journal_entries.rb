class AddAnalyticalFieldsJournalEntries < ActiveRecord::Migration
  def up
    add_reference :journal_entry_items, :project_budget, index: true, foreign_key: true
    add_column :journal_entry_items, :equipment_id, :integer
  end

  def down
    remove_reference :journal_entry_items, :project_budget, index: true, foreign_key: true
    remove_column :journal_entry_items, :equipment_id
  end
end
