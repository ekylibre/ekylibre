((E, $) ->
  'use strict'

  $(document).ready ->
    working_div = $('.apply-fy-date .controls')
    working_div.append($('#financial-year-dates'))
    alert_span = $('.apply-fy-date .controls #financial-year-dates')

    input = working_div.find('input')

    input.on 'dp.change', (e) ->
      current_date = new Date(e.date)
      started_date = new Date(alert_span.attr('started_on'))
      stopped_date = new Date(alert_span.attr('stopped_on'))

      if(started_date <= current_date && current_date <= stopped_date)
        alert_span.hide()
      else
        alert_span.show()
        
) ekylibre, jQuery
