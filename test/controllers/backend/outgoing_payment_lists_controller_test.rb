require 'test_helper'
module Backend
  class OutgoingPaymentListsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    # TODO: Re-activate the #export_to_sepa test
    test_restfully_all_actions except: %i[export_to_sepa]
  end
end
