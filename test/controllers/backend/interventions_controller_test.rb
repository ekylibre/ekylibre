require 'test_helper'

module Backend
  class InterventionsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions set: :show, except: %i[run change_state change_page compute unroll purchase sell modal purchase_order_items compare_realised_with_planned create_duplicate_intervention]
    # , compute: { mode: create params: { format: json } }
    # TODO: Re-activate #compute, #change_state, #unroll, #purchase, #sell,
    # #modal, #change_page and #purchase_order_items test
  end
end
