class AddIsNumberValidToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :number_is_valid, :boolean, null: false, default: false

    reversible do |d|
      d.up do
        execute <<-SQL
          UPDATE accounts
          SET number_is_valid = true
        SQL

        execute <<-SQL
          UPDATE accounts
          SET number_is_valid = false
          WHERE nature = 'general'
          AND (number ~ '^[1-9]0*$|^0'
          OR LENGTH(number) <> 8)
        SQL
      end

      d.down do
        # NOOP
      end
    end
  end
end
