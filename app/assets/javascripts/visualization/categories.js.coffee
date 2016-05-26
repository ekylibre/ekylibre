class visualization.Categories

  constructor: (@layer, @data, options = {}) ->
    @items = []
    property = @layer.reference
    for zone in @data
      unless this.itemFor(zone[property])
        @items.push
          name: zone[property],
          color: zone['shapeColor']

    if this.valid()
      @items = @items.sort (a, b) ->
        a.name > b.name
      @colors = options.colors ? []
      if @items.length > @colors.length
        for x in [@colors.length..@items.length]
          @colors.push(options.parent.options.colors[x] ? "#000000")
      for item, index in @items
        if item.color?
          item.fillColor = item.color
        else
          item.fillColor = @colors[index]

      console.log "Categories computed"
    else
      console.warn "Invalid categories"

  # Build layer as wanted
  buildLayerGroup: (widget, globalStyle = {}) ->
    group = []
    for zone in @data
      zoneStyle =
        fillColor: this.itemFor(zone[@layer.reference]).fillColor
      zoneLayer = new L.GeoJSON(zone.shape, $.extend(true, {}, globalStyle, zoneStyle))
      widget._bindPopup(zoneLayer, zone)
      unless @layer.withoutGhostLabel
        label = new L.GhostLabel(className: 'leaflet-ghost-label', toBack: false).setContent(zone.name).toCentroidOfBounds(zoneLayer.getLayers()[0].getLatLngs())
        widget.ghostLabelCluster.bind label, zoneLayer.getLayers()[0]
      group.push(zoneLayer)
    group

  # Build HTML legend for given categories computed layer
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
    @items.length > 0

visualization.registerLayerType "categories", visualization.Categories
