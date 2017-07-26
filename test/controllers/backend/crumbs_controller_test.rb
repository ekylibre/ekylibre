require 'test_helper'
module Backend
  class CrumbsControllerTest < ActionController::TestCase
    # TODO: Re-activate #convert and #index tests
    test_restfully_all_actions except: %i[convert index] # convert: touch
  end
end
