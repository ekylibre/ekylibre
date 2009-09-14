# == Schema Information
#
# Table name: payments
#
#  account_id     :integer       
#  account_number :string(255)   
#  amount         :decimal(16, 2 not null
#  bank           :string(255)   
#  check_number   :string(255)   
#  company_id     :integer       not null
#  created_at     :datetime      not null
#  creator_id     :integer       
#  embanker_id    :integer       
#  embankment_id  :integer       
#  entity_id      :integer       
#  id             :integer       not null, primary key
#  lock_version   :integer       default(0), not null
#  mode_id        :integer       not null
#  paid_on        :date          
#  parts_amount   :decimal(16, 2 
#  received       :boolean       default(TRUE), not null
#  scheduled      :boolean       not null
#  to_bank_on     :date          default(CURRENT_DATE), not null
#  updated_at     :datetime      not null
#  updater_id     :integer       
#

require 'test_helper'

class PaymentTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
