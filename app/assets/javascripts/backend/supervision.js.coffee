#= require highcharts/highcharts
((E, $) ->

  ###
  # In order to synchronize tooltips and crosshairs, override the
  # built-in events with handlers defined on the parent element.
  ###

  ###
  # Synchronize zooming through the setExtremes event handler.
  ###
  E.syncExtremes = (e) ->
    console.log "sync extremes"
    thisChart = @chart
    Highcharts.each Highcharts.charts, (chart) ->
      if chart != thisChart
        if chart.xAxis[0].setExtremes
          # It is null while updating
          chart.xAxis[0].setExtremes e.min, e.max

  $(document).on 'mousemove touchmove', '#graphs *[data-sync-chart]', (e) ->
    chart = $(this).highcharts()
    masterSerie = chart.hoverSeries ? chart.series[0]
    masterPoint = masterSerie.searchPoint(e, true)
    for chart in Highcharts.charts
      e = chart.pointer.normalize(e)
      for s in chart.series
        serie = s if s.name == masterSerie.name
      serie ?= chart.hoverSeries
      serie ?= chart.series[0]
      point = serie.searchPoint(e, true)
      if point
        # Show the hover marker
        if serie.visible
          point.onMouseOver()
        else
          serie.onMouseOut()
        # Show the tooltip
        chart.tooltip.refresh point
        # Show the crosshair
        chart.xAxis[0].drawCrosshair e, point
    # Show point on map
    map = $('#map .map')
    if point
       map.find('.crumb.hover').each ->
        L.DomUtil.removeClass(this, 'hover')
      console.log map.find(".crumb-t#{point.x}")
      L.DomUtil.addClass(map.find(".crumb-t#{point.x}")[0], 'hover')
      console.log map.find(".crumb-t#{point.x}")


  ###
  # Override the reset function, we don't need to hide the tooltips and crosshairs.
  ###

  Highcharts.Pointer::reset = ->

  $(document).ready ->
    $('*[data-sync-chart]').each () ->
      element = $(this)
      console.log element
      dataset = element.data('sync-chart')
      element.highcharts
        chart:
          marginLeft: 40
          spacingTop: 20
          spacingBottom: 20
          height: 250
          eventszzzz:
            load: () ->
              console.log ">>", new Date, (new Date()).getTime()
              series = @series
              setInterval((() ->
                d = new Date
                console.log "ok", d, d.getTimezoneOffset()
                x = d.getTime() - d.getTimezoneOffset() * 60 * 1000
                for serie in series
                  y = 100 * Math.random()
                  console.log "#{x}, #{y}"
                  serie.addPoint([x, y], true, true)
                ), 5000)
              return

        title:
          text: null
        credits:
          enabled: false
        legend:
          enabled: true
        xAxis:
          type: 'datetime'
          crosshair: true
          events:
            setExtremes: E.syncExtremes
        yAxis:
          title:
            text: null
        tooltip:
          pointFormat: "{point.y} #{dataset.unit}"
        series: dataset.series
    setTimeout(( ->
      $(window).trigger('resize')
      ), 400)

) ekylibre, jQuery
