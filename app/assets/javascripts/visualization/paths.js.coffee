# visualization.Paths class
# displays crumbs by intervention as a path
#
# @data is an array of hashes containing info to display
# @layer is the layer name
#
# ==== examples
#
# @data is an array of hashes built according to the following model:
# * minimal example of a hash representing a crumb:
#   item  {
#           name:         <intervention name>,  # may be the date, the doer's name,
#                                               # whatever you want as long as all the crumbs
#                                               # for a given intervention have the same one.
#                                               # This is what is called in the
#                                               # VisualizationHelper to build the legend if
#                                               # you wrote something like:
#                                               #   = visualization do |v|
#                                               #     - v.serie :crumbs, my_array_of_crumbs_hashes
#                                               #     - v.paths :name, :crumbs
#                                               # :name being the @layer parameter the constructor requires.
#           nature:       crumb.nature,         # proper to the crumb. May be one of the natures
#                                               # enumerated in Crumb model.
#                                               # this option is used to display particular points
#                                               # bigger and to change the path opacity for parts
#                                               # that correspond to actual works (points between a
#                                               # hard_start) and a hard_stop crumb
#           shape:        crumb.geolocation,    # proper to the crumb. contains the actual crumb
#                                               # location as a Charta::Geometry object.
#                                               # This is what is used to draw the crumb on the map
#  }
class visualization.Paths

  constructor: (@layer, @data, options = {}) ->
    @items = []
    property = @layer.reference
    for crumb in @data
      unless this.itemFor(crumb[property])
        @items.push
          name: crumb[property]

    if this.valid()
      @items = @items.sort (a, b) ->
        a.name > b.name
      @colors = options.colors ? []
      if @items.length > @colors.length
        for x in [@colors.length..@items.length]
          @colors.push(visualization.colors[x] ? "#000000")
      for item, index in @items
        item.fillColor = @colors[index]

      console.log "Paths computed"
    else
      console.warn "Invalid paths"

  # Build layer as wanted
  buildLayerGroup: (widget, globalStyle = {}) ->
    group = []
    # defining styles
    strokeWidth = 4
    crumbStyle =
      radius: strokeWidth
      stroke: true
      weight: strokeWidth/2
      color: "#000000"
      fillColor: "#FFFFFF"
      opacity: 1
    lineStyle =
      weight: strokeWidth
      stroke: true
      color: this.itemFor(@data[0][@layer.reference]).fillColor
      fillColor: "rgba(0,0,0,0)"
      opacity: 1

    # drawing line
    points = []
    current_name = @data[0].name
    current_color = this.itemFor(@data[0][@layer.reference]).fillColor
    for crumb in @data
      if crumb.name != current_name
        lineStyle.color = current_color
        lineLayer = new L.polyline(points, $.extend(true, {}, globalStyle, lineStyle))
        group.push(lineLayer)
        points = []
        current_name = crumb.name
        current_color = this.itemFor(crumb[@layer.reference]).fillColor
      points.push(new L.geoJson(crumb.shape).getBounds().getCenter())
    if points.length > 0
      lineStyle.color = current_color
      lineLayer = new L.polyline(points, $.extend(true, {}, globalStyle, lineStyle))
      group.push(lineLayer)
    # drawing circles
    for crumb in @data
      crumbStyle.color= this.itemFor(crumb[@layer.reference]).fillColor
      if crumb.nature == 'hard_start'
        crumbStyle.fillColor = "#000000"
      if crumb.nature == 'hard_stop'
        crumbStyle.fillColor = "#FFFFFF"
      crumbLayer = new L.circleMarker(new L.geoJson(crumb.shape).getBounds().getCenter(), $.extend(true, {}, globalStyle, crumbStyle))
      widget._bindPopup(crumbLayer, crumb)
      group.push(crumbLayer)
    group

  # Build HTML legend for given paths computed layer
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

  # Check if paths are valid
  valid: () ->
    @items.length > 0

visualization.registerLayerType "paths", visualization.Paths
