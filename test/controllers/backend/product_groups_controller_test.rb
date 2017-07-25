require 'test_helper'
module Backend
  class ProductGroupsControllerTest < ActionController::TestCase
    # TODO: Re-activate #index and #list, #show and #edit tests
    test_restfully_all_actions except: [:index, :list, :edit, :show]
  end
end
