class AddDefaultCompanyBornAt < ActiveRecord::Migration
  def up
    started_on = select_value("SELECT LEAST(COALESCE(started_on, '2008-01-01'), COALESCE(entities.born_at, '2008-01-01')::DATE) FROM (SELECT MIN(started_on) AS started_on
 FROM financial_years
 WHERE id IN (SELECT financial_year_id FROM journal_entry_items)
    OR id IN (SELECT financial_year_id FROM journal_entries)
    OR id IN (SELECT financial_year_id FROM tax_declarations)
    OR id IN (SELECT financial_year_id FROM fixed_asset_depreciations)
    OR id IN (SELECT financial_year_id FROM inventories)
    OR id IN (SELECT financial_year_id FROM financial_year_exchanges)
    OR id IN (SELECT financial_year_id FROM account_balances)
) AS x, entities
 WHERE of_company") || '2008-01-01'

    # Removes useless financial_years
    execute "DELETE FROM financial_years WHERE started_on < '#{started_on}'"
    # Adjusts born_at value for Entity.of_company
    execute "UPDATE entities SET born_at = '#{started_on}' WHERE of_company"
    # Adds constraint
    execute 'ALTER TABLE entities ADD CONSTRAINT company_born_at_not_null CHECK ((of_company = FALSE) OR (of_company = TRUE AND born_at IS NOT NULL))'
  end

  def down
    execute 'ALTER TABLE entities DROP CONSTRAINT company_born_at_not_null'
  end
end
