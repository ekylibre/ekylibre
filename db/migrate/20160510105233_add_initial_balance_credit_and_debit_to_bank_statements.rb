class AddInitialBalanceCreditAndDebitToBankStatements < ActiveRecord::Migration
  def change
    add_column :bank_statements, :initial_balance_debit,  :decimal, null: false, precision: 19, scale: 4, default: 0.0
    add_column :bank_statements, :initial_balance_credit, :decimal, null: false, precision: 19, scale: 4, default: 0.0
  end
end
