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

  constructor: (@layer, @data, @options = {}) ->
    if this.valid()
      @options.color ?= visualization.colors[0]
      @options.fillColor ?= @options.color
      console.log "Paths computed", @options
    else
      console.warn "Invalid paths"

  # Build layer as wanted
  buildLayerGroup: (widget, globalStyle = {}) ->
    group = []
    for crumb in @data
      crumbLayer = new L.circleMarker(new L.geoJson(crumb.shape).getBounds().getCenter(), $.extend(true, {}, globalStyle, @options, {className: "crumb crumb-#{crumb.name}"}))
      widget._bindPopup(crumbLayer, crumb)
      group.push(crumbLayer)
      previous_crumb = @data[@data.indexOf(crumb) - 1]
      if previous_crumb
        points = []
        points.push(new L.geoJson(previous_crumb.shape).getBounds().getCenter())
        points.push(new L.geoJson(crumb.shape).getBounds().getCenter())
        crumbLayer = new L.polyline(points, $.extend(true, {}, globalStyle, @options))
        group.push(crumbLayer)
    return group

  # Build HTML legend for given paths computed layer
  buildLegend: () ->
    html  = "<div class='leaflet-legend-item' id='legend-#{@layer.name}'>"
    html += "<div class='leaflet-legend-body leaflet-categories-scale'>"
    html += "<span class='leaflet-categories-items'>"
    html += "<span class='leaflet-categories-item'>"
    html += "<i class='leaflet-categories-sample' style='background-color: #{@options.color};'></i>"
    html += " #{@layer.label}"
    html += "</span>"
    html += "</span>"
    html += "</div>"
    html += "</div>"
    return html

  # Check if paths are valid
  valid: () ->
    true

visualization.registerLayerType "path", visualization.Path
