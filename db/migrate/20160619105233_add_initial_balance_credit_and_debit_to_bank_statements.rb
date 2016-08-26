class AddInitialBalanceCreditAndDebitToBankStatements < ActiveRecord::Migration
  def change
    add_column :bank_statements, :initial_balance_debit,  :decimal, null: false, precision: 19, scale: 4, default: 0.0
    add_column :bank_statements, :initial_balance_credit, :decimal, null: false, precision: 19, scale: 4, default: 0.0
    change_column :bank_statements, :started_at, :date
    rename_column :bank_statements, :started_at, :started_on
    change_column :bank_statements, :stopped_at, :date
    rename_column :bank_statements, :stopped_at, :stopped_on
  end
end
