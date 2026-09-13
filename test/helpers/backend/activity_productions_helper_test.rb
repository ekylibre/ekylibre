require 'test_helper'

module Backend
  class ActivityProductionsHelperTest < ActionView::TestCase
    include ChartsHelper
    include Backend::ThemeHelper

    test 'production_cost_charts returns html' do
      activity_production = create(:activity_production)
      charts = production_cost_charts(activity_production)
      # Le contrat est `data-echarts` depuis la bascule de Highcharts vers
      # ECharts ; seul le nom des helpers est resté (`column_highcharts`).
      refute_empty Nokogiri::HTML(charts).search('div[data-echarts]')
    end
  end
end
