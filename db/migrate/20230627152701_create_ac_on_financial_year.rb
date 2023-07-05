class CreateAcOnFinancialYear < ActiveRecord::Migration[5.2]
  def up
    add_column :financial_years, :accounting_system, :string
    add_column :accounts, :active, :boolean, null: false, default: true
    if connection.select_value("SELECT count(*) FROM preferences WHERE name = 'accounting_system' AND nature = 'accounting_system'") > 0
      execute <<~SQL
        UPDATE financial_years SET accounting_system = (SELECT string_value FROM preferences WHERE name = 'accounting_system' AND nature = 'accounting_system')
      SQL
      execute <<~SQL
        UPDATE accounts SET active = TRUE
      SQL
    end
  end

  def down
    remove_column :financial_years, :accounting_system
    remove_column :accounts, :active
  end
end
