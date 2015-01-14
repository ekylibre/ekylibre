class visualization.Points

  constructor: (@layer, @data, @options = {}) ->
    @items = []
    console.log "Layer: ", @layer
    for zone in @data
      lnglat = zone.shape.coordinates
      @items.push
        name: zone.name
        point: [lnglat[1], lnglat[0]]
        radius: zone.radius ? @options.radius
    if this.valid()
      @items = @items.sort (a, b) ->
        a.name > b.name
      @colors = @options.colors ? []
      if @items.length > @colors.length
        for x in [@colors.length..@items.length]
          @colors.push(visualization.colors[x] ? "#000000")
      for item, index in @items
        item.fillColor = @colors[index]
      console.log "Points computed"
    else
      console.warn "Invalid categories"

  # Build layer as wanted
  buildLayerGroup: (widget, globalStyle = {}) ->
    group = []
    # Shadow
    if @options.stroke
      for zone in @items
        zoneStyle =
          fillColor: zone.color ? @options.color
          radius: (zone.radius ? @options.radius) + @options.weight
          stroke: false
          fillOpacity: 0.8
        console.log zone.point
        group.push new L.circleMarker(zone.point, zoneStyle)
    # Core
    for zone in @items
      console.log zone
      zoneStyle =
        fillColor: zone.fillColor ? @options.fillColor
        radius: zone.radius ? @options.radius
        stroke: false
        fillOpacity: 1
      console.log zoneStyle
      zoneLayer = new L.circleMarker(zone.point, zoneStyle)
      widget._bindPopup(zoneLayer, zone)
      group.push(zoneLayer)
    group

  # Build HTML legend for given points computed layer
  buildLegend: () ->
    html  = "<div class='leaflet-legend-item' id='legend-#{@layer.name}'>"
    html += "<h3>#{@layer.label}</h3>"
    html += "<div class='leaflet-legend-body leaflet-categories-scale'>"
    html += "<span class='leaflet-categories-items'>"
    for name, item of @items
      html += "<span class='leaflet-categories-item'>"
      html += "<i class='leaflet-categories-sample' style='background-color: #{item.fillColor};'></i>"
      html += " #{item.name}"
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

visualization.registerLayerType "points", visualization.Points
