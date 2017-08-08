require 'test_helper'
module Backend
  class OutgoingPaymentListsControllerTest < ActionController::TestCase
    # TODO: Re-activate the #export_to_sepa test
    test_restfully_all_actions except: :export_to_sepa
  end
end
