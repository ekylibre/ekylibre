class UpdateLetteredAt < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        disable_triggers

        # set lettered_at for all entry_items to the last printed_on (max_printed_on) of entry_items group (with the same letter and same account_id)
        # if lettered_at < max_printed_on
        execute <<~SQL
          UPDATE journal_entry_items j
          SET lettered_at = modified_letter_groups.max_printed_on
          FROM (SELECT letter AS letter,
                       account_id AS account_id,
                      SUM(debit) - SUM(credit) AS balance,
                      MAX(printed_on) as max_printed_on
                FROM journal_entry_items
          		  WHERE letter IS NOT NULL AND letter NOT ILIKE '%*'
                GROUP BY letter, account_id
                    ) modified_letter_groups
          WHERE modified_letter_groups.account_id = j.account_id
          AND modified_letter_groups.letter = j.letter
          AND modified_letter_groups.balance = 0.0
          AND j.letter IS NOT NULL AND j.letter NOT ILIKE '%*';
        SQL

        enable_triggers
      end

      dir.down do
        #NOPE
      end
    end
  end

  def disable_triggers
    execute <<~SQL
      ALTER TABLE journal_entry_items DISABLE TRIGGER compute_partial_lettering_status_insert_delete;
      ALTER TABLE journal_entry_items DISABLE TRIGGER compute_partial_lettering_status_update;
      ALTER TABLE journal_entries DISABLE TRIGGER compute_journal_entries_continuous_number_on_insert;
      ALTER TABLE journal_entries DISABLE TRIGGER compute_journal_entries_continuous_number_on_update;
      ALTER TABLE journal_entries DISABLE TRIGGER synchronize_jeis_of_entry;
      ALTER TABLE journal_entry_items DISABLE TRIGGER synchronize_jei_with_entry;
    SQL
  end

  def enable_triggers
    execute <<~SQL
      ALTER TABLE journal_entry_items ENABLE TRIGGER compute_partial_lettering_status_insert_delete;
      ALTER TABLE journal_entry_items ENABLE TRIGGER compute_partial_lettering_status_update;
      ALTER TABLE journal_entries ENABLE TRIGGER compute_journal_entries_continuous_number_on_insert;
      ALTER TABLE journal_entries ENABLE TRIGGER compute_journal_entries_continuous_number_on_update;
      ALTER TABLE journal_entries ENABLE TRIGGER synchronize_jeis_of_entry;
      ALTER TABLE journal_entry_items ENABLE TRIGGER synchronize_jei_with_entry;
    SQL
  end
end
