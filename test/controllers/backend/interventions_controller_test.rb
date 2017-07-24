require 'test_helper'

module Backend
  class InterventionsControllerTest < ActionController::TestCase
    test_restfully_all_actions set: :show, except: [:run, :change_state, :change_page] #, compute: { mode: :create, params: { format: :json } }
    # TODO: Re-activate #compute, #change_state and #change_page test
  end
end
