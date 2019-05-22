class SetMissingValidatedAtAndContinuousNumbersOnJournalEntries < ActiveRecord::Migration
  def up
    execute <<-SQL
      ALTER TABLE journal_entries
        DISABLE TRIGGER compute_journal_entries_continuous_number_on_update;

      UPDATE journal_entries
         SET validated_at = COALESCE(grouped_jeis.updated_at, NOW())
        FROM (SELECT entry_id,
                     MAX(updated_at) AS updated_at
                FROM journal_entry_items
               WHERE state = 'confirmed'
                  OR state = 'draft'
            GROUP BY entry_id) AS grouped_jeis
       WHERE id = grouped_jeis.entry_id
         AND validated_at IS NULL
         AND (state = 'confirmed'
          OR state = 'closed');

      UPDATE journal_entries
         SET continuous_number = numbered_entries.number
        FROM (SELECT id,
                     ROW_NUMBER() OVER (ORDER BY validated_at) as number
                FROM journal_entries
             ) AS numbered_entries
        WHERE journal_entries.id = numbered_entries.id
          AND (state = 'confirmed'
            OR state = 'closed');

      ALTER TABLE journal_entries
        ENABLE TRIGGER compute_journal_entries_continuous_number_on_update;
    SQL
  end

  def down
    # NOOP
  end
end
