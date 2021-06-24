class RenameChartsOfAccounts < ActiveRecord::Migration[4.2]
  def up
    execute "UPDATE preferences SET name = 'accounting_system' WHERE name = 'chart_of_accounts'"
    execute "UPDATE preferences SET nature = 'accounting_system' WHERE nature = 'chart_of_accounts'"
  end
end
