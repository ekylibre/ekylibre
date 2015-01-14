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
class visualization.Path

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
    for crumb in @data
      radius = 1.0
      if crumb.nature != 'point'
        radius = 2.5
      crumbStyle =
        fillColor: this.itemFor(crumb[@layer.reference]).fillColor
        color: this.itemFor(crumb[@layer.reference]).fillColor
        opacity: opacity
      crumbLayer = new L.circle(new L.geoJson(crumb.shape).getBounds().getCenter(), radius, $.extend(true, {}, globalStyle, crumbStyle))
      widget._bindPopup(crumbLayer, crumb)
      group.push(crumbLayer)
      previous_crumb = @data[@data.indexOf(crumb) - 1]
      if previous_crumb
        points = []
        points.push(new L.geoJson(previous_crumb.shape).getBounds().getCenter())
        points.push(new L.geoJson(crumb.shape).getBounds().getCenter())
        crumbLayer = new L.polyline(points, $.extend(true, {}, globalStyle, crumbStyle))
        if crumb.nature == 'hard_start'
          opacity = 1
        if crumb.nature == 'hard_stop'
          opacity = 0.2
        group.push(crumbLayer)
    group

  # Build HTML legend for given paths computed layer
  buildLegend: () ->
    html  = "<div class='leaflet-legend-item' id='legend-#{@layer.name}'>"
    html += "<div class='leaflet-legend-body leaflet-categories-scale'>"
    html += "<span class='leaflet-categories-items'>"
    html += "<span class='leaflet-categories-item'>"
    html += "<i class='leaflet-categories-sample' style='background-color: #{@items[0].fillColor};'></i>"
    html += " #{@layer.label}"
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

visualization.registerLayerType "path", visualization.Path
