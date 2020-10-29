class AddAlreadyExistingToFinancialYears < ActiveRecord::Migration
  def change
    add_column :financial_years, :already_existing, :boolean, null: false, default: false
  end
end
