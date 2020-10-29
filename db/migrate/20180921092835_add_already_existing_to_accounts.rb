class AddAlreadyExistingToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :already_existing, :boolean, null: false, default: false

    reversible do |d|
      d.up do
        execute <<-SQL
          UPDATE accounts
          SET already_existing = true
        SQL
      end

      d.down do
        # NOOP
      end
    end
  end
end
