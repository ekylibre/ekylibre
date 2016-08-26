# Needs base HighCharts files
#
#= require highcharts/highcharts
#= require highcharts/highcharts-more

(($) ->
  "use strict"

  $.widget "ui.highchart",
    options:
      chart:
        style:
          fontFamily: "\"Open Sans\", \"Droid Sans\", \"Liberation Sans\", Helvetica, sans-serif"
          fontSize: "13px"
      credits:
        enabled: false
      tooltip:
        enabled: true
      legend:
        enabled: false
      title:
        text: ""

    _create: ->
      $.extend(true, @options, @element.data("highcharts"))
      @element.highcharts @options

    _destroy: ->
      console.log("No highcharts destroy")

  $.loadHighcharts = ->
    $("*[data-highcharts]").each ->
      chartitem = $(this)
      chartitem.highchart()
    return

  $(document).ready $.loadHighcharts
  $(document).on "page:load cocoon:after-insert cell:load", $.loadHighcharts

) jQuery
