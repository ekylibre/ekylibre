class mapeditor.Simple

  constructor: (@layer, @data, @options = {}) ->

  buildLayerGroup: (widget, globalStyle = {}) ->
    if @data == 'no_data'
      L.featureGroup()
    else
      L.geoJson(@data, {
        onEachFeature: (feature, layer) =>
          feature.properties['internal_id'] = new Date().getTime()
          if feature.properties.name
            label = new L.GhostLabel(className: 'leaflet-ghost-label', toBack: false).setContent(feature.properties.name).toCentroidOfBounds(layer.getLatLngs())
            widget.ghostLabelCluster.bind label, layer
          feature.properties['popupAttributes'] = globalStyle.popup || []
          widget.popupizeSerie(feature, layer) if @layer.popup

        style: (feature) =>
          $.extend {}, true, globalStyle, feature.properties
      })

  buildLegend: () ->
    html  = "<div class='leaflet-legend-item' id='legend-#{@layer.name}'>"
    # html += "<h3>#{@layer.label}</h3>"
    html += "<div class='leaflet-legend-body leaflet-categories-scale'>"
    html += "<span class='leaflet-categories-items'>"
    html += "<span class='leaflet-categories-item'>"
    html += "<i class='leaflet-categories-sample' style='background-color: #{@layer.fillColor || @options.parent.options.show.layerDefaults[@layer.type].fillColor };'></i>"
    html += " <span class='leaflet-categories-item_label'>#{@layer.label}</span>"
    html += "</span>"
    html += "</span>"
    html += "</div>"
    html += "</div>"
    return html

  # Check if categories are valid
  valid: () ->
    true

mapeditor.registerLayerType "simple", mapeditor.Simple
