class mapeditor.Categories

  constructor: (@layer, @data, @options = {}) ->
    @items = []


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

          @items.push({name: feature.properties[@layer.reference], fillColor: feature.properties.color}) unless this.itemFor(feature.properties[@layer.reference])

        style: (feature) =>
          $.extend {}, true, globalStyle, feature.properties
      })

  buildLegend: () ->
    html  = "<div class='leaflet-legend-item' id='legend-#{@layer.name}'>"
    html += "<h3>#{@layer.label}</h3>"
    html += "<div class='leaflet-legend-body leaflet-categories-scale'>"
    html += "<span class='leaflet-categories-items'>"
    for name, item of @items
      html += "<span class='leaflet-categories-item'>"
      html += "<i class='leaflet-categories-sample' style='background-color: #{item.fillColor};'></i>"
      html += " <span class='leaflet-categories-item_label'>#{item.name}</span>"
      html += "</span>"
    html += "</span>"
    html += "</div>"
    html += "</div>"
    return html

# Returns the item matching the given name
  itemFor: (name) ->
    back = null
    @items.forEach (item, index, array) ->
      back = item if item.name == name
    return back

# Check if categories are valid
  valid: () ->
    true

mapeditor.registerLayerType "categories", mapeditor.Categories
