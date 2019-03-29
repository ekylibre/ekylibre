require 'test_helper'
module Backend
  class CapIsletsControllerTest < ActionController::TestCase
    # TODO: Re-activate #convert test
    test_restfully_all_actions except: :convert
  end
end
