require 'test_helper'
module Backend
  class FixedAssetDepreciationsControllerTest < ActionController::TestCase
    # TODO: Re-activate #show test
    test_restfully_all_actions except: :show
  end
end
