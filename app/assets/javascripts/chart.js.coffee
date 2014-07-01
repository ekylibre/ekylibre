# Needs base HighCharts files
#
#= require highcharts/highcharts
#= require highcharts/highcharts-more

(($) ->
  "use strict"

  $.widget "ui.chart",
    options:
      chart:
        style:
          fontFamily: "\"Open Sans\", \"Droid Sans\", \"Liberation Sans\", Helvetica, sans-serif"
          fontSize: "14px"
      credits:
        enabled: false
      tooltip:
        enabled: true
      legend:
        enabled: false
      title:
        text: ""

    _create: ->
      $.extend(true, @options, @element.data("chart"))
      @element.highcharts @options

    _destroy: ->
      console.log("No chart destroy")

  $.loadCharts = ->
    $("*[data-chart]").each ->
      $(this).chart()
    return

  $(document).ready $.loadCharts
  $(document).on "page:load cocoon:after-insert cell:load", $.loadCharts

) jQuery
