class AddAlreadyExistingToFinancialYears < ActiveRecord::Migration[4.2]
  def change
    add_column :financial_years, :already_existing, :boolean, null: false, default: false
  end
end
