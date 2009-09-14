# == Schema Information
#
# Table name: payment_parts
#
#  amount       :decimal(16, 2 
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  downpayment  :boolean       not null
#  id           :integer       not null, primary key
#  invoice_id   :integer       
#  lock_version :integer       default(0), not null
#  order_id     :integer       
#  payment_id   :integer       not null
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

require 'test_helper'

class PaymentPartTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
