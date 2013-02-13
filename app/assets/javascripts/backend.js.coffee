jQuery ->
  # $(document).on('load load.cell', "*[data-chart]", ->
  # $(document).behave(events, selector, function)
  $.behave('*[data-chart]', 'load', ->
    element = $(this)
    vals = element.attr("data-values")
    if vals != null and vals != undefined
      r = Raphael(element.attr("id"))
      r.barchart(0, 0, 400, 200, $.parseJSON(vals))
    false
  )
  true
