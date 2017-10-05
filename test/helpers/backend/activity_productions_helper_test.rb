require 'test_helper'

module Backend
  class ActivityProductionsHelperTest < ActionView::TestCase
    include ChartsHelper
    include Backend::ThemeHelper

    test 'production_cost_charts returns html' do
      activity_production = create(:activity_production)
      charts = production_cost_charts(activity_production)
      refute_empty Nokogiri::HTML(charts).search('div[data-highcharts]')
    end
  end
end
