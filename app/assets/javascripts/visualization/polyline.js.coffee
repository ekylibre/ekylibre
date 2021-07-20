# visualization.Polyline class
# displays Stringline
#
# @data is an array of one hash containing info to display
# @layer is the layer name
#
# ==== examples
#
# @data is an array of one hash built according to the following model:
# * minimal example of a hash representing a linestring:
#   item  {
#           name:         <intervention name>,  # This is what is called in the
#                                               # VisualizationHelper to build the legend if
#                                               # you wrote something like:
#                                               #   = visualization do |v|
#                                               #     - v.serie :stringline, my_array_of_hash_polyline
#                                               #     - v.polyline :name, :stringline
#                                               # :name being the @layer parameter the constructor requires.
#           shape:        stringline.shape,    # proper to the linestring. contains the actual linestring
#                                               # location as a Charta::Geometry linestring object.
#                                               # This is what is used to draw the linestring on the map
#  }
class visualization.Polyline

  constructor: (@layer, @data, @options = {}) ->
    if this.valid()
      console.log "Paths computed"
    else
      console.warn "Invalid paths"

  buildLayerGroup: (widget, globalStyle = {}) ->
    group = []
    # Reverse lng-lat to lat-lng for Leaflet
    for coordinate in @data[0].shape.coordinates
      coordinate.reverse()

    latlngs = @data[0].shape.coordinates
    lineLayer = new L.polyline(latlngs, @options)
    group.push(lineLayer)
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

visualization.registerLayerType "polyline", visualization.Polyline