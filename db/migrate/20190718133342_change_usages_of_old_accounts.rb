class ChangeUsagesOfOldAccounts < ActiveRecord::Migration
  def up
    execute <<-SQL
      UPDATE accounts
         SET usages = 'making_services_expenses'
       WHERE usages = 'services_expenses'
    SQL
  end

  def down
    execute <<-SQL
      UPDATE accounts
         SET usages = 'services_expenses'
       WHERE usages = 'making_services_expenses'
    SQL
  end
end
