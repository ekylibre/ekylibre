class NullifyStockAccountIdAndStockMovementAccountIdForVariantsWhoseAccountsDontExist < ActiveRecord::Migration
  def up
    execute <<-SQL
      UPDATE product_nature_variants
      SET stock_movement_account_id = NULL
      WHERE NOT EXISTS (
        SELECT 1
        FROM accounts
        WHERE accounts.id = stock_movement_account_id)
    SQL

    execute <<-SQL
      UPDATE product_nature_variants
      SET stock_account_id = NULL
      WHERE NOT EXISTS (
        SELECT 1
        FROM accounts
        WHERE accounts.id = stock_account_id)
    SQL
  end

  def down
    # NOOP ?
  end
end
