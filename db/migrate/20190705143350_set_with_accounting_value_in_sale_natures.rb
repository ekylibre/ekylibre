class SetWithAccountingValueInSaleNatures < ActiveRecord::Migration
  def up
    execute <<-SQL
      UPDATE sale_natures
        SET journal_id = j.id
      FROM (SELECT id
            FROM journals
            WHERE nature = 'sales'
            LIMIT 1) AS j
      WHERE with_accounting = false;
    SQL

    remove_column :sale_natures, :with_accounting
  end

  def down
    # NOOP
  end
end
