class SetReconcilableForAuxiliaryAccounts < ActiveRecord::Migration[4.2]
  def up
    execute <<-SQL
      UPDATE accounts
        SET reconcilable = true
      WHERE nature = 'auxiliary'
    SQL
  end

  def down
    # NOOP
  end
end
