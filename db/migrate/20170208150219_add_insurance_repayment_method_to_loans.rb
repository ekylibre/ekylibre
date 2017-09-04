class AddInsuranceRepaymentMethodToLoans < ActiveRecord::Migration
  def change
    add_column :loans, :insurance_repayment_method, :string
  end
end
