class NormalizeAccountNumber < ActiveRecord::Migration
  NON_GENERAL_ACCOUNTS = %w[401 411 421 467 301 302 310 320 330 340 374 375 376 603].freeze
  def change
    add_column :accounts, :auxiliary_number, :string
    add_column :accounts, :nature, :string
    add_reference :accounts, :centralizing_account, references: :accounts
    reversible do |d|
      d.up do
        # Set all accounts nature to 'general'
        execute <<-SQL
          UPDATE accounts
          SET nature = 'general'
        SQL

        NON_GENERAL_ACCOUNTS.each do |account|
          # Set specific accounts nature to 'centralizing' and number now only contains 3 digits
          execute <<-SQL
            UPDATE accounts
            SET nature = 'centralizing',
                number = '#{account}'
            WHERE number = '#{account}'
          SQL

          # Create centralizing account if there is auxiliary account not attached with centralizing account because it doesn't exist
          execute <<-SQL
            INSERT INTO accounts (number, name, label, nature, created_at, updated_at)
              SELECT number, name, label, 'centralizing', NOW(), NOW()
              FROM (SELECT SUBSTRING(number, 0, 4) AS number, SUBSTRING(number, 0, 4) AS name, SUBSTRING(number, 0, 4) AS label
                    FROM accounts
                    WHERE number ~ '^(#{account})(?=.+$)'
                    AND centralizing_account_id IS NULL) AS missing_centralizing_account
              WHERE NOT missing_centralizing_account.number IN (SELECT number
                                                                FROM accounts
                                                                WHERE nature = 'centralizing')
              LIMIT 1
          SQL

          # Set specific accounts nature to 'auxiliary' and associate it with its 'centralizing' account, number is the concatenation of centralizing account with auxiliary_number
          execute <<-SQL
            UPDATE accounts
            SET nature = 'auxiliary',
                auxiliary_number = SUBSTRING(number, 4),
                centralizing_account_id = (SELECT id
                                           FROM accounts
                                           WHERE number = '#{account}' LIMIT 1)
            WHERE number ~ '^(#{account})(?=.+$)'
          SQL
        end
      end

      d.down do
        # NOOP
      end
    end
  end
end
