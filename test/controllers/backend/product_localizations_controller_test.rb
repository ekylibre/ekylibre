require 'test_helper'

module Backend
  class ProductLocalizationsControllerTest < ActionController::TestCase
    # TODO: Re-activate #destroy test
    test_restfully_all_actions except: :destroy
  end
end
