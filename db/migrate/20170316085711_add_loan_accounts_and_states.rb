class AddLoanAccountsAndStates < ActiveRecord::Migration
  def change
    ## Add states

    add_column :loans, :state, :string
    add_column :loans, :ongoing_at, :datetime
    add_column :loans, :repaid_at, :datetime

    execute "UPDATE loans SET state = 'ongoing', ongoing_at = NOW()"

    # # Add loan accounts

    add_column :loans, :loan_account_id, :integer
    add_column :loans, :interest_account_id, :integer
    add_column :loans, :insurance_account_id, :integer
    add_column :loans, :use_bank_guarantee, :boolean
    add_column :loans, :bank_guarantee_account_id, :integer
    add_column :loans, :bank_guarantee_amount, :integer
    add_column :loans, :accountable_repayments_started_on, :date
    add_column :loans, :initial_releasing_amount, :boolean, default: false, null: false

    add_column :loan_repayments, :accountable, :boolean, default: false, null: false
    add_column :loan_repayments, :locked, :boolean, default: false, null: false

    # # Update mandatory loans accounts

    loans_account = Account.find_or_import_from_nomenclature(:loans)
    interests_account = Account.find_or_import_from_nomenclature(:loans_interests)

    unless loans_account.nil? && interests_account.nil?
      execute("UPDATE loans SET loan_account_id = #{loans_account.id}, interest_account_id = #{interests_account.id}")
    end
  end
end
