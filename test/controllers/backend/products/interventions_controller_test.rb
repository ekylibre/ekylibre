require 'test_helper'
module Backend
  module Products
    class InterventionsControllerTest < ActionController::TestCase
      test_restfully_all_actions except: :has_harvesting

      test 'nothing' do
      end
    end
  end
end
