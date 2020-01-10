require 'test_helper'

module Backend
  class ProductLocalizationsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    # TODO: Re-activate #destroy test
    test_restfully_all_actions except: :destroy
  end
end
