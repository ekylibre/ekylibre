class RemoveNatureAndWithAccountingFromPurchaseNature < ActiveRecord::Migration[4.2]
  def change
    res = execute <<-SQL
      SELECT count(*) as journal_count FROM journals WHERE nature = 'purchases'
    SQL
    res = res.to_a.first['journal_count'].to_i

    if res.zero?
      execute <<-SQL
        INSERT INTO journals (nature, name, code, closed_on, currency, used_for_affairs, used_for_gaps, created_at, updated_at, creator_id, updater_id, lock_version, custom_fields, used_for_permanent_stock_inventory, used_for_unbilled_payables, used_for_tax_declarations, accountant_id)
        VALUES ('purchases', 'Achats', 'ACHA', '2011-12-31', 'EUR', false, false, now(), now(), null, null, 0, null, false, false, false, null);
      SQL
    end


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
