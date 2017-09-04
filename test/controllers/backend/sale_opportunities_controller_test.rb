require 'test_helper'
module Backend
  class SaleOpportunitiesControllerTest < ActionController::TestCase
    # TODO: Re-activate #detach_gaps test
    test_restfully_all_actions except: %i[select attach detach detach_gaps finish]
  end
end
