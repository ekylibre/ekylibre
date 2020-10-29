class SetReconcilableForAuxiliaryAccounts < ActiveRecord::Migration
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
