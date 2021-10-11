class ChangeUsagesOfOldAccountsToMatchNomenclature < ActiveRecord::Migration[4.2]
  CHANGED = { fixed_asset_depreciations: :financial_asset_depreciations,
              fixed_assets: :financial_assets,
              fixed_assets_suppliers: :financial_assets_suppliers ,
              fixed_assets_values: :financial_assets_values }

  def up
    CHANGED.each do |to, from|
      execute <<-SQL
        UPDATE accounts
           SET usages = '#{to}'
         WHERE usages = '#{from}'
      SQL
    end
  end

  def down
    CHANGED.each do |to, from|
      execute <<-SQL
        UPDATE accounts
           SET usages = '#{from}'
         WHERE usages = '#{to}'
      SQL
    end
  end
end
