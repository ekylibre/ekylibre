require 'test_helper'

module Backend
  class InterventionsControllerTest < ActionController::TestCase
    test_restfully_all_actions set: :show, except: %i[run change_state change_page compute unroll purchase sell modal purchase_order_items]
    # , compute: { mode: create params: { format: json } }
    # TODO: Re-activate #compute, #change_state, #unroll, #purchase, #sell,
    # #modal, #change_page and #purchase_order_items test
  end
end
