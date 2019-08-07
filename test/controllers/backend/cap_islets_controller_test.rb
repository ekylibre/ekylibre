require 'test_helper'
module Backend
  class CapIsletsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    # TODO: Re-activate #convert test
    test_restfully_all_actions except: :convert
  end
end
