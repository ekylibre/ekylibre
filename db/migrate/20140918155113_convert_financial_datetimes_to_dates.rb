class ConvertFinancialDatetimesToDates < ActiveRecord::Migration
  def change
    for table, extras in { financial_years: [], financial_assets: %i[purchased_at ceded_at], financial_asset_depreciations: [] }
      for column_name in %i[started_at stopped_at] + extras
        new_column_name = column_name.to_s.gsub(/\_at$/, '_on').to_sym
        rename_column table, column_name, new_column_name
        change_column table, new_column_name, :date
      end
    end
  end
end
