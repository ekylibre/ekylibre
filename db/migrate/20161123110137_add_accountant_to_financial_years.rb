class AddAccountantToFinancialYears < ActiveRecord::Migration
  def change
    change_table :financial_years do |t|
      t.references :accountant, index: true
    end
  end
end
