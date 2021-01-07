class AddInsuranceRepaymentMethodToLoans < ActiveRecord::Migration[4.2]
  def change
    add_column :loans, :insurance_repayment_method, :string
  end
end
