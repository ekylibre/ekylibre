class AddLoanBeforeColumn < ActiveRecord::Migration
  def change
    add_column :loan_repayments, :locked, :boolean, default: false, null: false
    add_column :loans, :initial_releasing_amount, :boolean, default: false, null: false
    add_column :loans, :accountable_repayments_started_on, :date
  end
end
