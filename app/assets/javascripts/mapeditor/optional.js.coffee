class mapeditor.Optional

  constructor: (@layer, @data, @options = {}) ->

  buildLayerGroup: (widget, globalStyle = {}) ->
    group = []
    for feature in @data.features
      zoneLayer = new L.GeoJSON(feature, globalStyle)
      group.push(zoneLayer)
    L.layerGroup(group)

  buildLegend: () ->
    html  = "<div class='leaflet-legend-item' id='legend-#{@layer.name}' style='display: none;'>"
    html += "<div class='leaflet-legend-body leaflet-categories-scale'>"
    html += "<span class='leaflet-categories-items'>"
    html += "<span class='leaflet-categories-item'>"
    html += "<i class='leaflet-categories-sample' style='background-color: #{@layer.fillColor || @options.parent.options.show.layerDefaults[@layer.type].fillColor };'></i>"
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

mapeditor.registerLayerType "optional", mapeditor.Optional
