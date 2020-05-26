class AddMissingReferenceNumberOnEntries < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        # update null entry reference_number from not null sale reference_number or sale number
        execute <<-SQL
          UPDATE journal_entries
          SET reference_number = COALESCE(sales.reference_number, sales.number)
          FROM sales
          WHERE journal_entries.resource_id = sales.id
          AND journal_entries.resource_type = 'Sale'
          AND journal_entries.reference_number IS NULL
          AND sales.reference_number IS NOT NULL
        SQL

        # update null entry reference_number from not null purchase reference_number or purchase number
        execute <<-SQL
          UPDATE journal_entries
          SET reference_number = COALESCE(purchases.reference_number, purchases.number)
          FROM purchases
          WHERE journal_entries.resource_id = purchases.id
          AND journal_entries.resource_type = 'Purchase'
          AND journal_entries.reference_number IS NULL
          AND purchases.reference_number IS NOT NULL
        SQL

      end
    end
  end
end
