class ChangeBalanceToJournalEntries < ActiveRecord::Migration
  def change
    add_column :journal_entries, :real_balance, :decimal, precision: 19, scale: 4,  default: 0.0, null: false
    add_column :journal_entry_items, :real_balance, :decimal, precision: 19, scale: 4, default: 0.0, null: false

    reversible do |r|
      r.up do
        execute <<-SQL
          UPDATE journal_entries
          SET balance = debit - credit
        SQL

        execute <<-SQL
          UPDATE journal_entries
          SET real_balance = real_debit - real_credit
        SQL

        execute <<-SQL
          UPDATE journal_entry_items
          SET balance = debit - credit
        SQL

        execute <<-SQL
          UPDATE journal_entry_items
          SET real_balance = real_debit - real_credit
        SQL
      end

      r.down do
        # We keep old values except on JournalEntryItem which are the only ones to be null
        execute <<-SQL
          UPDATE journal_entry_items
          SET balance = 0
        SQL
      end
    end
  end
end
