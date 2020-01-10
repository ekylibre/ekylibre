require 'test_helper'
module Backend
  class IntegrationsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    # TODO: Re-activate #update, #create, #destroy, #new and #check tests
    test_restfully_all_actions except: %i[update create destroy new check]
  end
end
