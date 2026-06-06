require 'test_helper'

class ChartsHelperTest < ActionView::TestCase
  # These tests pin the contract that ChartsHelper emits `data-echarts`
  # with the correct series.type. They do not assert visual rendering.

  def extract_options(html)
    match = html.match(/data-echarts="([^"]+)"/)
    raise "no data-echarts attribute in: #{html.inspect}" unless match
    JSON.parse(CGI.unescapeHTML(match[1]))
  end

  test 'column_highcharts emits bar series with categories' do
    html = column_highcharts([{ name: 'A', data: [1, 2, 3] }], x_axis: { categories: %w[a b c] })
    opts = extract_options(html)
    assert_equal 'bar', opts['series'].first['type']
    assert_equal 'category', opts['xAxis']['type']
    assert_equal %w[a b c], opts['xAxis']['data']
  end

  test 'spline_highcharts emits line series with smooth' do
    html = spline_highcharts([{ name: 'A', data: [1, 2] }])
    opts = extract_options(html)
    assert_equal 'line', opts['series'].first['type']
    assert_equal true, opts['series'].first['smooth']
  end

  test 'area_highcharts emits line with areaStyle' do
    html = area_highcharts([{ name: 'A', data: [1, 2] }])
    opts = extract_options(html)
    assert_equal 'line', opts['series'].first['type']
    assert_equal({}, opts['series'].first['areaStyle'])
  end

  test 'pie_highcharts emits pie series with default radius' do
    html = pie_highcharts([{ name: 'A', data: [{ name: 'x', value: 1 }] }])
    opts = extract_options(html)
    assert_equal 'pie', opts['series'].first['type']
    assert_equal '70%', opts['series'].first['radius']
    assert_nil opts['xAxis']
  end

  test 'bar_highcharts inverts axes' do
    html = bar_highcharts([{ name: 'A', data: [1, 2] }], x_axis: { categories: %w[a b] })
    opts = extract_options(html)
    assert_equal 'bar', opts['series'].first['type']
    assert_equal 'category', opts['xAxis']['type']
  end

  test 'line_highcharts emits plain line' do
    html = line_highcharts([{ name: 'A', data: [1, 2] }])
    opts = extract_options(html)
    assert_equal 'line', opts['series'].first['type']
    assert_nil opts['series'].first['smooth']
  end

  test 'bubble_highcharts emits scatter with symbolSize formula' do
    html = bubble_highcharts([{ name: 'A', data: [[1, 2, 3]] }])
    opts = extract_options(html)
    assert_equal 'scatter', opts['series'].first['type']
    assert_match(/Math\.sqrt/, opts['series'].first['symbolSize'])
  end

  test 'waterfall_highcharts emits stacked bars + connector line' do
    html = waterfall_highcharts([{ data: [10, -3, 5, { name: 'sum', isSum: true }] }])
    opts = extract_options(html)
    # 4 stacked bar series (placeholder, gain, loss, total) + 1 connector line
    assert_equal 5, opts['series'].size
    bars = opts['series'].select { |s| s['type'] == 'bar' }
    assert_equal 4, bars.size
    assert(bars.all? { |s| s['stack'] == 'waterfall' })
    connector = opts['series'].find { |s| s['type'] == 'line' }
    assert_equal '__connector', connector['name']
    # Sum point ends up in the totals series at position 3
    totals = bars.find { |s| s['name'].to_s.match?(/total/i) }
    assert_equal 12, totals['data'][3] # 10 - 3 + 5 = 12
  end

  test 'plot_options column stacking propagates to series.stack' do
    html = column_highcharts([{ name: 'A', data: [1] }, { name: 'B', data: [2] }],
                             plot_options: { column: { stacking: 'normal' } })
    opts = extract_options(html)
    assert_equal 'group', opts['series'].first['stack']
    assert_equal 'group', opts['series'].last['stack']
  end

  test 'legend true is converted to {show: true}' do
    html = column_highcharts([{ name: 'A', data: [1] }], legend: true)
    opts = extract_options(html)
    assert_equal true, opts['legend']['show']
  end

  test 'tooltip point_format converts highcharts placeholders' do
    html = column_highcharts([{ name: 'A', data: [1] }],
                             tooltip: { point_format: '{point.y: 1f} kg for {point.name}' })
    opts = extract_options(html)
    assert_equal '{c} kg for {b}', opts['tooltip']['formatter']
  end

  test 'drilldown option is forwarded under __drilldown' do
    html = column_highcharts([{ name: 'A', data: [{ y: 1, drilldown: 'x' }] }],
                             drilldown: { series: { 'x' => [{ name: 'x', data: [1] }] } })
    opts = extract_options(html)
    assert opts['__drilldown'], 'expected __drilldown to be present'
    assert_equal [{ 'name' => 'x', 'data' => [1] }], opts['__drilldown']['series']['x']
  end

  test 'pie data points {name,y,color} are translated to ECharts shape' do
    series = [{
      name: 'Activities',
      data: [{ name: 'wheat', y: 12.5, color: '#abc123' }, { name: 'corn', y: 3.0, color: '#def456' }]
    }]
    html = pie_highcharts(series)
    opts = extract_options(html)
    pts = opts['series'].first['data']
    assert_equal 12.5, pts[0]['value']
    refute pts[0].key?('y'), 'y should be translated to value'
    assert_equal({ 'color' => '#abc123' }, pts[0]['itemStyle'])
    assert_equal 'wheat', pts[0]['name']
  end

  test 'pie size + inner_size become radius donut array' do
    series = [{ name: 'Inner', data: [{ name: 'a', y: 1 }], size: '60%', inner_size: '30%' }]
    html = pie_highcharts(series)
    opts = extract_options(html)
    assert_equal %w[30% 60%], opts['series'].first['radius']
  end

  test 'multi-ring pie (cropping_plan_cell shape) emits 2 pie series with translated points' do
    series = [
      { name: 'Activities',   data: [{ name: 'a', y: 1, color: '#111111' }], size: '60%', data_labels: { enabled: false } },
      { name: 'Productions',  data: [{ name: 'p', y: 2, color: '#222222' }], size: '80%', inner_size: '60%', data_labels: { enabled: true } }
    ]
    html = pie_highcharts(series, tooltip: { point_format: '{point.y: 1.2f} ha' })
    opts = extract_options(html)
    assert_equal 2, opts['series'].size
    # First ring: single radius
    assert_equal '60%', opts['series'][0]['radius']
    assert_equal false, opts['series'][0]['label']['show']
    # Second ring: donut radius
    assert_equal %w[60% 80%], opts['series'][1]['radius']
    assert_equal true, opts['series'][1]['label']['show']
    # Points translated
    assert_equal 1, opts['series'][0]['data'][0]['value']
    assert_equal({ 'color' => '#111111' }, opts['series'][0]['data'][0]['itemStyle'])
  end

  test 'category x_axis without explicit categories derives them from series data point names' do
    series = [{ data: [
      { name: 'Q1', y: 10 },
      { name: 'Q2', y: -3 },
      { name: 'Q3', y: 7 }
    ] }]
    html = waterfall_highcharts(series, x_axis: { type: 'category' })
    opts = extract_options(html)
    assert_equal %w[Q1 Q2 Q3], opts['xAxis']['data']
  end

  test 'category x_axis with explicit categories keeps them' do
    html = column_highcharts([{ name: 'A', data: [1, 2] }], x_axis: { type: 'category', categories: %w[a b] })
    opts = extract_options(html)
    assert_equal %w[a b], opts['xAxis']['data']
  end

  test 'unsupported types raise NotImplementedError' do
    assert_raises(NotImplementedError) do
      packedbubble_highcharts([{ name: 'A', data: [1] }])
    end
    assert_raises(NotImplementedError) do
      area_range_highcharts([{ name: 'A', data: [1] }])
    end
  end
end
