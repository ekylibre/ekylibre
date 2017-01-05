require 'test_helper'

class PaymentTest < ActiveSupport::TestCase
  test 'ensure sign of amount is different in Incoming and Outgoing payments' do
    assert_equal 0, IncomingPayment.sign_of_amount + OutgoingPayment.sign_of_amount
  end
end