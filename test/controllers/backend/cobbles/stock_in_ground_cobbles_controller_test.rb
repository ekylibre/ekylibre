require 'test_helper'
module Backend
  module Cobbles
    class StockInGroundCobblesControllerTest < ActionController::TestCase
      test 'show action' do
        user = create(:user)
        sign_in(user)
        activity = create :corn_activity, :fully_inspectable
        get :show, id: activity.id, dimension: :net_mass
        refute_empty Nokogiri::HTML(response.body).search('div[data-highcharts]')
      end
    end
  end
end
