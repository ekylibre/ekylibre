class AddLoanAccountsAndStates < ActiveRecord::Migration
  ACCOUNTS = (YAML.safe_load <<-YAML).deep_symbolize_keys.freeze
    loans:
      fr_pcg82: 164
    loans_interests:
      fr_pcg82: 661
  YAML

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

    # # Update mandatory loans accounts

    loan_account = execute("select id from accounts where number = '#{ACCOUNTS[:loans][:fr_pcg82]}'").first
    interest_account = execute("select id from accounts where number = '#{ACCOUNTS[:loans_interests][:fr_pcg82]}'").first

    unless loan_account.nil? && interest_account.nil?
      loan_account_id = loan_account['id']
      interest_account_id = interest_account['id']

      execute("UPDATE loans SET loan_account_id = #{loan_account_id}, interest_account_id = #{interest_account_id}")
    end
  end
end
