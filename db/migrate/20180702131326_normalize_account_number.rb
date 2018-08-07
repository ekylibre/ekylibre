class NormalizeAccountNumber < ActiveRecord::Migration
  CENTRALIZING_ACCOUNTS = { 'suppliers': '401', 'clients': '411' }.freeze
  def change
    add_column :accounts, :auxiliary_number, :string
    add_column :accounts, :nature, :string
    add_column :accounts, :centralizing_account_name, :string
    reversible do |d|
      d.up do
        # Set all accounts nature to 'general'
        execute <<-SQL
          UPDATE accounts
          SET nature = 'general'
        SQL

        CENTRALIZING_ACCOUNTS.each do |name, number|
          # Set specific accounts nature to 'auxiliary' and associate it with its 'centralizing' account IN nomenclature, number is the concatenation of centralizing account number with auxiliary_number
          execute <<-SQL
            UPDATE accounts
            SET nature = 'auxiliary',
                auxiliary_number = SUBSTRING(number, 4),
                centralizing_account_name = '#{name}'
            WHERE number ~ '^(#{number})(?=.+$)'
          SQL
        end
      end

      d.down do
        # NOOP
      end
    end
  end
end
