class AddFinancialYearStartAtToEntity < ActiveRecord::Migration[4.2]
  def change
    add_column :entities, :first_financial_year_ends_on, :date
  end
end
