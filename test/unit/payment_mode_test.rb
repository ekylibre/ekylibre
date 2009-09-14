# == Schema Information
#
# Table name: payment_modes
#
#  account_id      :integer       
#  bank_account_id :integer       
#  company_id      :integer       not null
#  created_at      :datetime      not null
#  creator_id      :integer       
#  id              :integer       not null, primary key
#  lock_version    :integer       default(0), not null
#  mode            :string(5)     
#  name            :string(50)    not null
#  nature          :string(1)     default("U"), not null
#  updated_at      :datetime      not null
#  updater_id      :integer       
#

require 'test_helper'

class PaymentModeTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
