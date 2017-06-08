require 'test_helper'

module Backend
  class InterventionsControllerTest < ActionController::TestCase
    test_restfully_all_actions compute: { mode: :create, params: { format: :json } }, set: :show, except: :run
  end
end
