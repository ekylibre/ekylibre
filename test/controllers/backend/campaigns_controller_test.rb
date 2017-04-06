require 'test_helper'

module Backend
  class CampaignsControllerTest < ActionController::TestCase
    test_restfully_all_actions except: %i[open current]

    test 'open action in post mode' do
      post :open, locale: @locale, activity_id: activities(:activities_001).id, id: campaigns(:campaigns_001).id
      assert_redirected_to backend_campaign_path(campaigns(:campaigns_001))
    end

    test 'current action in get mode' do
      get :current, locale: @locale
      assert_redirected_to backend_campaign_path(@user.current_campaign)
    end
  end
end
