require 'test_helper'

module Backend
  class LoansControllerTest < ActionController::TestCase
    test_restfully_all_actions

    test "create without ongoing_at" do
      user = User.last
      user.sign_in
      
    end
  end
end
