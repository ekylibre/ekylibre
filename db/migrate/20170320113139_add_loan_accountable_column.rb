class AddLoanAccountableColumn < ActiveRecord::Migration
  def change
    add_column :loan_repayments, :accountable, :boolean, default: false, null: false

    # execute ('UPDATE loan_repayments SET accountable = true WHERE journal_entry_id IS NOT NULL')
  end
end
