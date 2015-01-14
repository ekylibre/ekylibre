# Add sprockets directives below:
#= require visualization/gradient
#

class visualization.Bubbles extends visualization.Gradient

  constructor: (@layer, @data, options = {}) ->
    options.levelNumber ?= 5

    super @data, @layer.reference, options

    if this.valid()

      # Compute radius
      options.startRadius ?= 4
      options.stopRadius  ?= 24
      start = options.startRadius
      stop  = options.stopRadius
      for grade in @grades
        level = grade.index / (@levelNumber - 1.0)
        grade.radius = start + Math.round((stop - start) * level)
        grade.fillColor = options.fillColor
        grade.color  = options.color
        grade.weight = options.weight
        grade.stroke = options.stroke
      console.log "Radiuses computed"
    else
      console.warn "Invalid bubbles"

  # Build layer as wanted
  buildLayerGroup: (widget, globalStyle = {}) ->
    group = []
    # Shadow
    for zone in @data
      grade = this.gradeFor(zone[@layer.reference])
      if grade.stroke
        zoneStyle =
          fillColor: grade.color
          radius: grade.radius + grade.weight
          stroke: false
          fillOpacity: 0.8
        group.push new L.CircleMarker(this._centroid(zone.shape), zoneStyle)
    # Core
    for zone in @data
      grade = this.gradeFor(zone[@layer.reference])
      zoneStyle =
        fillColor: grade.fillColor
        radius: grade.radius
        stroke: false
        fillOpacity: 1
      zoneLayer = new L.CircleMarker(this._centroid(zone.shape), zoneStyle)
      widget._bindPopup(zoneLayer, zone)
      group.push(zoneLayer)
    group

  # Build HTML legend for given bubbles computed layer
  buildLegend: () ->
    html  = "<div class='leaflet-legend-item' id='legend-#{@layer.name}'>"
    html += "<h3>#{@layer.label}</h3>"
    html += "<div class='leaflet-legend-body leaflet-bubbles-scale'>"
    html += "<span class='min-value'>#{@grades[0].minLabel}</span>"
    html += "<span class='leaflet-bubbles-grades'>"
    for grade in @grades
      html += "<i class='leaflet-bubbles-grade' style='width: #{2 * grade.radius}px; height: #{2 * grade.radius}px; background-color: #{grade.fillColor}; border-width: #{grade.weight}px; border-color: #{grade.color}' title='#{grade.minLabel} ~ #{grade.maxLabel}'></i>"
    html += "</span>"
    html += "<span class='max-value'>#{@grades[@levelNumber - 1].maxLabel}</span>"
    html += "</div>"
    html += "</div>"
    return html

  # Compute a centroid based on bounds
  # The point can be out of the surface...
  _centroid: (shape) ->
    geojson = new L.GeoJSON(shape)
    return geojson.getBounds().getCenter()

visualization.registerLayerType "bubbles", visualization.Bubbles
