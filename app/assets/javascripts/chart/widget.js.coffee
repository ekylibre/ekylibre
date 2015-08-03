((C, $) ->
  "use strict"

  $.widget "ui.chart",
    options:
      engine: "c3"

    _create: ->
      $.extend(true, @options, @element.data("chart"))
      if C.adapters[@options.engine]?
        @chartObject = C.adapters[@options.engine].render(@element, @options)
      else
        console.error "Cannot handle chart engine: #{@options.engine}"

    _destroy: ->
      console.log("No chart destroy")

  $.loadCharts = ->
    $("*[data-chart]").each ->
      $(this).chart()
    return

  $(document).ready $.loadCharts
  $(document).on "page:load cocoon:after-insert cell:load", $.loadCharts

) chart, jQuery
