require 'test_helper'
module Backend
  class ProductsControllerTest < ActionController::TestCase
    # TODO: Re-activate #show and #edit tests
    test_restfully_all_actions except: %i[show edit]
  end
end
