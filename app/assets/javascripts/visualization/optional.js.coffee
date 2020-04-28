class visualization.Optional

  constructor: (@layer, @data, @options = {}) ->

  # Build layer as wanted
  buildLayerGroup: (widget, globalStyle = {}) ->
    group = []
    for zone in @data
      zoneLayer = new L.GeoJSON(zone.shape, globalStyle)
      widget._bindPopup(zoneLayer, zone)
      group.push(zoneLayer)
    group

  # Build HTML legend for given categories computed layer
  buildLegend: () ->
    html = "<div class='leaflet-legend-item' id='legend-#{@layer.name}' style='display: none;'>"
    html += "<div class='leaflet-legend-body leaflet-categories-scale'>"
    html += "<span class='leaflet-categories-items'>"
    html += "<span class='leaflet-categories-item'>"
    html += "<i class='leaflet-categories-sample' style='background-color: #{@layer.fillColor || @options.parent.options.layerDefaults[@layer.type].fillColor };'></i>"
    html += "<span class='leaflet-categories-item_label'>#{@layer.label}</span>"
    html += "<span class='leaflet-categories-item_label zoom-guidance'>(#{@options.zoomGuidance})</span>"
    html += "</span>"
    html += "</span>"
    html += "</div>"
    html += "</div>"
    return html

  # Check if categories are valid
  valid: () ->
    true

visualization.registerLayerType 'optional', visualization.Optional
