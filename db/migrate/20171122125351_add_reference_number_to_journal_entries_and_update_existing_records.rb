class AddReferenceNumberToJournalEntriesAndUpdateExistingRecords < ActiveRecord::Migration
  def change
    add_column :journal_entries, :reference_number, :string
    reversible do |d|
      d.up do
        execute <<-SQL.strip_heredoc
          UPDATE journal_entries AS je
            SET reference_number = s.number
          FROM sales AS s
          WHERE je.reference_number IS NULL
            AND je.resource_id = s.id AND je.resource_type = 'Sale'
        SQL

        execute <<-SQL.strip_heredoc
          UPDATE journal_entries AS je
            SET reference_number = p.reference_number
          FROM purchases AS p
          WHERE je.reference_number IS NULL
            AND je.resource_id = p.id AND je.resource_type = 'Purchase'
        SQL
      end

      d.down do
        # NOOP
      end
    end
  end
end
