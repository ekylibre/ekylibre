(($) ->
  'use strict'

  $(document).ready ->

    if $('.timeline-chart-block').length > 0

      timeline_datas = JSON.parse($('.timeline-chart-block').attr('data-timeline'))
      timeline_events = JSON.parse($('.timeline-chart-block').attr('data-events'))
      element = $('#' + timeline_datas.chart_id)[0]

      timeline = new TimelineChart(element, timeline_datas.datas, timeline_events, {
        start_date: new Date(timeline_datas.min_date),
        end_date: new Date(timeline_datas.max_date),
        zoom_out_limit: TimelineChart.DEFAULT_ZOOM_SCALE
      })

) jQuery
