class FixRailsComplianceToJournalEntry < ActiveRecord::Migration[5.0]
  def change
    reversible do |dir|
      dir.up do
        change_column_default :journal_entries, :compliance, from: '{}', to: {}
        execute "UPDATE journal_entries SET compliance = '{}'::jsonb WHERE compliance = '\"{}\"'"
      end
      dir.down do
        change_column_default :journal_entries, :compliance, from: {}, to: '{}'
        execute "UPDATE journal_entries SET compliance = '\"{}\"' WHERE compliance = '{}'::jsonb"
      end
    end
  end
end
