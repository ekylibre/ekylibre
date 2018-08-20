require 'test_helper'
module Backend
  module Cobbles
    class ProductionCostCobblesControllerTest < ActionController::TestCase
      test 'show action' do
        user = create(:user)
        sign_in(user)
        activity_production = create(:activity_production)
        get :show, id: activity_production.id
        refute_empty Nokogiri::HTML(response.body).search('div[data-highcharts]')
      end
    end
  end
end
