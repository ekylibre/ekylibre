# Add sprockets directives below:
#= require visualization/gradient

class visualization.Choropleth extends visualization.Gradient

  constructor: (@layer, @data, options = {}) ->
    super @data, @layer.reference, options

    if this.valid()

      # Compute colors
      start = new visualization.Color(options.startColor)
      stop  = new visualization.Color(options.stopColor)
      for grade in @grades
        level = grade.index / (@levelNumber - 1.0)
        grade.fillColor = visualization.Color.toString
          red:   start.red   + (Math.round(stop.red   - start.red)   * level)
          green: start.green + (Math.round(stop.green - start.green) * level)
          blue:  start.blue  + (Math.round(stop.blue  - start.blue)  * level)
      console.log "Colors computed"
    else
      console.warn "Invalid choropleth for #{@layer.reference}"
      console.warn @data

  # Build layer as wanted
  buildLayerGroup: (widget, globalStyle = {}) ->
    group = []
    for zone in @data
      zoneStyle =
        fillColor: this.gradeFor(zone[@layer.reference]).fillColor
      zoneLayer = new L.GeoJSON(zone.shape, $.extend(true, {}, globalStyle, zoneStyle))
      widget._bindPopup(zoneLayer, zone)
      group.push(zoneLayer)
    group

  # Build HTML legend for given choropleth computed layer
  buildLegend: () ->
    html  = "<div class='leaflet-legend-item' id='legend-#{@layer.name}'>"
    html += "<h3>#{@layer.label}"+ if @layer.unit then " (#{@layer.unit})" else "" +"</h3>"
    html += "<div class='leaflet-legend-body leaflet-choropleth-scale'>"
    html += "<span class='min-value'>#{@grades[0].minLabel}</span>"
    html += "<span class='max-value'>#{@grades[@levelNumber - 1].maxLabel}</span>"
    html += "<span class='leaflet-choropleth-grades'>"
    for grade in @grades
      html += "<i class='leaflet-choropleth-grade' style='width: #{100 / @levelNumber}%; background-color: #{grade.fillColor}' title='#{grade.minLabel} ~ #{grade.maxLabel}'></i>"
    html += "</span>"
    html += "</div>"
    html += "</div>"
    return html

visualization.registerLayerType "choropleth", visualization.Choropleth
