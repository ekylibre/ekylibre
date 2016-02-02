require 'test_helper'

module Backend
  class ActivityProductionsControllerTest < ActionController::TestCase
    test_restfully_all_actions new: { params: { activity_id: 1, campaign_id: 6 } }, create: { params: { activity_id: 1, campaign_id: 6 } }
  end
end
