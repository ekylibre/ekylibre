# == Schema Information
#
# Table name: account_balances
#
#  account_id       :integer       not null
#  company_id       :integer       not null
#  created_at       :datetime      not null
#  creator_id       :integer       
#  financialyear_id :integer       not null
#  global_balance   :decimal(16, 2 default(0.0), not null
#  global_count     :integer       default(0), not null
#  global_credit    :decimal(16, 2 default(0.0), not null
#  global_debit     :decimal(16, 2 default(0.0), not null
#  id               :integer       not null, primary key
#  local_balance    :decimal(16, 2 default(0.0), not null
#  local_count      :integer       default(0), not null
#  local_credit     :decimal(16, 2 default(0.0), not null
#  local_debit      :decimal(16, 2 default(0.0), not null
#  lock_version     :integer       default(0), not null
#  updated_at       :datetime      not null
#  updater_id       :integer       
#

require 'test_helper'

class AccountBalanceTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
