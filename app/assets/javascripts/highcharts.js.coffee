# Needs base HighCharts files
#
#= require highcharts/highcharts
#= require highcharts/highcharts-more

(($) ->
  "use strict"
  Highcharts.setOptions
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

  $.fn.highchartsFromData = ->
    $(this).each ->
      chart = $(this)
      options = {}
      if chart.prop("highchartLoaded") isnt true
        options.chart = chart.data("highchart")
        
        #  OPTIONS: colors, credits, exporting, labels, legend, loading, navigation, pane, plot-options, series, subtitle, title, tooltip, x-axis, y-axis
        options.series = chart.data("highchartSeries")  if chart.data("highchartSeries") isnt `undefined`
        options.colors = chart.data("highchartColors")  if chart.data("highchartColors") isnt `undefined`
        options.credits = chart.data("highchartCredits")  if chart.data("highchartCredits") isnt `undefined`
        options.exporting = chart.data("highchartExporting")  if chart.data("highchartExporting") isnt `undefined`
        options.labels = chart.data("highchartLabels")  if chart.data("highchartLabels") isnt `undefined`
        options.legend = chart.data("highchartLegend")  if chart.data("highchartLegend") isnt `undefined`
        options.loading = chart.data("highchartLoading")  if chart.data("highchartLoading") isnt `undefined`
        options.navigation = chart.data("highchartNavigation")  if chart.data("highchartNavigation") isnt `undefined`
        options.pane = chart.data("highchartPane")  if chart.data("highchartPane") isnt `undefined`
        options.plotOptions = chart.data("highchartPlotOptions")  if chart.data("highchartPlotOptions") isnt `undefined`
        options.subtitle = chart.data("highchartSubtitle")  if chart.data("highchartSubtitle") isnt `undefined`
        options.title = chart.data("highchartTitle")  if chart.data("highchartTitle") isnt `undefined`
        options.tooltip = chart.data("highchartTooltip")  if chart.data("highchartTooltip") isnt `undefined`
        options.xAxis = chart.data("highchartXAxis")  if chart.data("highchartXAxis") isnt `undefined`
        options.yAxis = chart.data("highchartYAxis")  if chart.data("highchartYAxis") isnt `undefined`
        chart.highcharts options
        chart.prop "highchartLoaded", true
      return

    return

  $.loadHighcharts = ->
    $("*[data-highchart]").highchartsFromData()
    return

  $(document).ready $.loadHighcharts
  $(document).on "page:load cocoon:after-insert cell:load", $.loadHighcharts
  return
) jQuery
