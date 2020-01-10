require 'test_helper'
module Backend
  module Products
    class InterventionsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
      test_restfully_all_actions except: :has_harvesting

      test 'nothing' do
      end
    end
  end
end
