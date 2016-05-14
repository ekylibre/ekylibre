require 'test_helper'
module Backend
  class InspectionsControllerTest < ActionController::TestCase
    test_restfully_all_actions new: { params: { activity_id: 1 } }, except: :create
  end
end
