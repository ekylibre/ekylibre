class ChangeUsagesOfOldAccounts < ActiveRecord::Migration
  def up
    execute <<-SQL
      UPDATE accounts
         SET usages = 'making_services_expenses'
       WHERE usages = 'services_expenses'
    SQL
  end

  def down
    #NOOP
  end
end
