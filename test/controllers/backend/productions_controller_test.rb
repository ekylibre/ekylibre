require 'test_helper'

class Backend::ProductionsControllerTest < ActionController::TestCase
  test_restfully_all_actions new: { activity_id: identify(:activities_001), campaign_id: identify(:campaigns_001) },
                             create: { production: { activity_id: identify(:activities_001), campaign_id: identify(:campaigns_001) } }
end
