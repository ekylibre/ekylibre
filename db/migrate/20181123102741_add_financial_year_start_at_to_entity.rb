class AddFinancialYearStartAtToEntity < ActiveRecord::Migration
  def change
    add_column :entities, :financial_year_start_at, :datetime
  end
end
