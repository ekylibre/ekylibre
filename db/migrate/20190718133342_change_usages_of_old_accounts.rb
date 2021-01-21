class ChangeUsagesOfOldAccounts < ActiveRecord::Migration[4.2]
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
