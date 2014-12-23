class NormalizeCatalogPriceThreads < ActiveRecord::Migration
  def up
    change_column :catalog_prices, :thread, :string, limit: 120
    for row in select_rows('SELECT DISTINCT variant_id, usage, catalog_id, indicator_name FROM catalog_prices JOIN catalogs ON (catalogs.id = catalog_id)')
      thread = row[1] + ':' + row[3] + ':' + Time.now.to_i.to_s(36) + ":" + rand(36 ** 16).to_s(36)
      execute "UPDATE catalog_prices SET thread = '#{thread}' FROM catalogs WHERE catalogs.id = catalog_id AND variant_id = #{row[0]} AND usage = '#{row[1]}' AND catalog_id = #{row[2]}"
    end
    change_column_null :catalog_prices, :thread, false
  end

  def down
    change_column_null :catalog_prices, :thread, true
  end
end
