class AddCloserToFinancialYears < ActiveRecord::Migration[4.2]
  def change
    add_reference :financial_years, :closer, index: true
    add_foreign_key :financial_years, :users, column: :closer_id
  end
end
