class AddComplianceToJournalEntry < ActiveRecord::Migration[4.2]
  def change
    add_column :journal_entries, :compliance, :jsonb, default: '{}'

    reversible do |dir|
      dir.up do
        query("CREATE INDEX journal_entries_compliance_index ON journal_entries USING gin ((compliance -> 'vendor'), (compliance -> 'name'))")
      end
      dir.down do
        query("DROP INDEX journal_entries_compliance_index")
      end
    end
  end
end
