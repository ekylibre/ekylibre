class AddFinancialYearStartAtToEntity < ActiveRecord::Migration
  def change
    add_column :entities, :first_financial_year_ends_on, :date
  end
end
