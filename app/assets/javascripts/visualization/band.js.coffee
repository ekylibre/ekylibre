class visualization.Band

  constructor: (@layer, @data, options = {}) ->
    @items = []
    property = @layer.reference
    console.log "Property: ", property
    previous = null
    minValue = null
    maxValue = null
    for zone in @data
      minValue ?= zone[property]
      maxValue ?= zone[property]
      minValue = zone[property] if minValue > zone[property]
      maxValue = zone[property] if maxValue < zone[property]
      if previous
        @items.push
          polygon: this.computeTrapez({x: previous.shape.coordinates[1], y: previous.shape.coordinates[0], w: previous.width}, {x: zone.shape.coordinates[1], y: zone.shape.coordinates[0], w: zone.width})
          value: zone[property]
          style:
            stroke: false
            fillOpacity: 1
      previous = zone
    if this.valid()
      start = new visualization.Color(options.startColor)
      stop  = new visualization.Color(options.stopColor)
      console.log(maxValue, minValue)
      for item in @items
        level = (item.value - minValue) / (maxValue - minValue)
        item.style.fillColor = visualization.Color.toString
          red:   start.red   + (Math.round(stop.red   - start.red)   * level)
          green: start.green + (Math.round(stop.green - start.green) * level)
          blue:  start.blue  + (Math.round(stop.blue  - start.blue)  * level)
      console.log "Bands computed"
    else
      console.warn "Invalid bands"

  # Build layer as wanted
  buildLayerGroup: (widget, globalStyle = {}) ->
    group = []
    for item in @items
      edge = new L.polygon(item.polygon, item.style)
      group.push(edge)
    group

  # Build HTML legend for given bands computed layer
  buildLegend: () ->
    html  = "<div class='leaflet-legend-item' id='legend-#{@layer.name}'>"
    html += "<h3>#{@layer.label}</h3>"
    # html += "<div class='leaflet-legend-body leaflet-categories-scale'>"
    # html += "<span class='leaflet-categories-items'>"
    # html += "<span class='leaflet-categories-item'>"
    # html += "<i class='leaflet-categories-sample' style='background-color: #{@items[0].fillColor};'></i>"
    # html += " #{@layer.label}"
    # html += "</span>"
    # html += "</span>"
    # html += "</div>"
    html += "</div>"
    return html

  # Returns the item matching the given name
  itemFor: (name) ->
    back = null
    @items.forEach (item, index, array) ->
      back = item if item.name == name
    return back

  # Check if bands are valid
  valid: () ->
    @items.length > 0

  # http://stackoverflow.com/questions/7854043/drawing-rectangle-between-two-points-with-arbitrary-width
  computeTrapez: (a, b) ->
    # Calculate a vector between start and end points
    v =
      x: b.x - a.x
      y: b.y - a.y

    # Then calculate a perpendicular to it (just swap X and Y coordinates)
    p =
      x:  v.y # Use separate variable otherwise you overwrite X coordinate here
      y: -v.x # Flip the sign of either the X or Y (edit by adam.wulf)

    # Normalize that perpendicular
    l = Math.sqrt(p.x * p.x + p.y * p.y); # That's length of perpendicular
    n =
      x: p.x / l
      y: p.y / l # Now N is normalized perpendicular

    # Calculate 4 points that form a rectangle by adding normalized perpendicular and multiplying it by half of the desired width
    ar = (a.w / 2) * 9 / 1000000
    br = (b.w / 2) * 9 / 1000000
    r1 = new L.LatLng(a.x + n.x * ar, a.y + n.y * ar)
    r2 = new L.LatLng(a.x - n.x * ar, a.y - n.y * ar)
    r3 = new L.LatLng(b.x + n.x * br, b.y + n.y * br)
    r4 = new L.LatLng(b.x - n.x * br, b.y - n.y * br)
    return [r1, r2, r4, r3]


visualization.registerLayerType "band", visualization.Band
