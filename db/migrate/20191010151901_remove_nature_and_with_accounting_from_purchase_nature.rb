class RemoveNatureAndWithAccountingFromPurchaseNature < ActiveRecord::Migration
  def change
    execute <<-SQL
      UPDATE purchase_natures
        SET journal_id = j.id
      FROM (SELECT id
            FROM journals
            WHERE nature = 'purchases'
            LIMIT 1) AS j
      WHERE with_accounting = false;
    SQL

    remove_column :purchase_natures, :currency
    remove_column :purchase_natures, :nature
    remove_column :purchase_natures, :with_accounting

    change_column_null :purchase_natures, :journal_id, false
    change_column_null :purchase_natures, :name, false
  end
end
