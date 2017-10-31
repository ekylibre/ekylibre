((E, $) ->
  'use strict'

  $(document).ready ->
    working_div = $('.apply-fy-date .controls')
    working_div.append($('#financial-year-dates'))
    input = working_div.find('input')

    $.checkDate(input)

    input.on 'dp.change', (e) ->
      $.checkDate(e)

  $.checkDate = (e) ->
    current_date = new Date(e.date || e.val())
    alert_span = $('.apply-fy-date .controls #financial-year-dates')

    started_date = new Date(alert_span.data('startedOn'))
    stopped_date = new Date(alert_span.data('stoppedOn'))

    if(!isNaN(current_date))
      if(started_date <= current_date && current_date <= stopped_date)
        alert_span.hide()
      else
        alert_span.show()


) ekylibre, jQuery
