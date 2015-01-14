class visualization.Heatmap

  constructor: (@layer, @data, options = {}) ->
    @items = []
    property = @layer.reference
    console.log property
    console.log @data
    for zone in @data
      coords =  zone.shape.coordinates
      @items.push [coords[1], coords[0], ]

    if this.valid()
      console.log "Heatmap computed"
    else
      console.warn "Invalid heatmap points"

  # Build layer as wanted
  buildLayerGroup: (widget, globalStyle = {}) ->
    group = []
    overlay = new L.TileLayer.WebGLHeatMap
      size: 12
      opacity: 0.8
      autoresize: true
    overlay.setData(@items)

    group.push(overlay)
    group

  # Build HTML legend for given categories computed layer
  buildLegend: () ->
    html  = "<div class='leaflet-legend-item' id='legend-#{@layer.name}'>"
    html += "<h3>#{@layer.label}</h3>"
    html += "<div class='leaflet-legend-body leaflet-categories-scale'>"
    # html += "<span class='leaflet-categories-items'>"
    # for name, item of @items
    #   html += "<span class='leaflet-categories-item'>"
    #   html += "<i class='leaflet-categories-sample' style='background-color: #{item.fillColor};'></i>"
    #   html += " #{item.name}"
    #   html += "</span>"
    # html += "</span>"
    html += "</div>"
    html += "</div>"
    return html

  # Check if categories are valid
  valid: () ->
    @items.length > 0

visualization.registerLayerType "heatmap", visualization.Heatmap
