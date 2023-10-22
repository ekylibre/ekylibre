class AddPayslipContributor < ActiveRecord::Migration[5.2]
  def change
    add_column :entities, :payslip_contributor, :boolean, null: false, default: false
    add_reference :entities, :payslip_contributor_account, index: true
    add_column :payslip_natures, :imported_centralizing_entries, :boolean, null: false, default: false
    add_column :payslips, :invoiced_at, :datetime
    add_column :payslips, :reference_number, :string  
    add_column :payslips, :description, :string
    add_column :payslips, :raw_amount, :decimal, precision: 19, scale: 4
    add_column :payslips, :source_revenue_amount, :decimal, precision: 19, scale: 4
    add_column :payslips, :social_security_amount, :decimal, precision: 19, scale: 4
    add_column :payslips, :other_social_expenses_amount, :decimal, precision: 19, scale: 4
    add_column :payslips, :total_company_social_amount, :decimal, precision: 19, scale: 4
  end
end


