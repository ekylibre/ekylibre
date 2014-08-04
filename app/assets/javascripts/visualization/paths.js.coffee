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
#           name:         <intervention name>,  # may be the date, the doer's name, whatever you want as long as all the crumbs
#                                               # for a given intervention have the same one. this is what is called in the 
#                                               # VisualizationHelper to build the legend if you wrote something like:
#                                               #   = visualization do |v|
#                                               #     - v.serie :crumbs, my_array_of_crumbs_hashes
#                                               #     - v.paths :name, :crumbs
#                                               # :name being the @layer parameter the constructor requires. 
#
#           nature:       crumb.nature,         # proper to the crumb. May be one of the natures enumerated in Crumb model. 
#                                               # this option is used to display particular points bigger and to change the 
#                                               # path opacity for parts that correspond to actual works (points between a hard_start)
#                                               # and a hard_stop crumb
#
#           shape:        crumb.geolocation,    # proper to the crumb. contains the actual crumb location as a Charta::Geometry object.
#                                               # This is what is used to draw the crumb on the map
#         }

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
          @colors.push(visualization.Paths.colors[x] ? "#000000")
      for item, index in @items
        item.fillColor = @colors[index]

      console.log "Paths computed"
    else
      console.warn "Invalid paths"

  # Build layer as wanted
  buildLayerGroup: (widget, globalStyle = {}) ->
    group = []
    for crumb in @data
      radius = 0.5
      if crumb.nature != 'point'
        radius = 5.0
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
    @items.find (item, index, array) ->
      item.name == name

  # Check if paths are valid
  valid: () ->
    @items.length > 0


# Generated colors in ruby
# $ p = Proc.new{[37 * rand(7), 255].min.to_i.to_s(16).rjust(2, "0")}
# $ (1..300).collect{|x| "##{p[]}#{p[]}#{p[]}"}.uniq
visualization.Paths.colors = ["#00de00", "#6f006f", "#4ade94", "#004ab9", "#de6f4a", "#b9b925", "#00b994", "#25946f", "#de00b9", "#94006f", "#de6f94", "#252594", "#dede94", "#4a2594", "#940000", "#deb9de", "#00b9b9", "#00de94", "#25254a", "#6fde6f", "#4a0094", "#256f4a", "#6f4a25", "#4a4a00", "#b9006f", "#4a6f25", "#6f946f", "#009425", "#6f4ade", "#2525de", "#b9946f", "#b9b994", "#b9de94", "#de256f", "#b900b9", "#4a4a6f", "#4a2525", "#006fde", "#940025", "#250094", "#b900de", "#4ab9b9", "#00004a", "#6f6fde", "#256fde", "#b92594", "#6f944a", "#6f6f25", "#4ab9de", "#de2525", "#2525b9", "#944a94", "#b94a94", "#946f94", "#b94a6f", "#000094", "#4a6f6f", "#006f00", "#946f4a", "#00256f", "#6f4a6f", "#de6fb9", "#6fdeb9", "#de6f00", "#94b94a", "#94b994", "#6f6fb9", "#b925de", "#de2594", "#dede25", "#6f4a94", "#946f6f", "#de25de", "#b92525", "#6fde94", "#254a25", "#4adeb9", "#00deb9", "#b9b9b9", "#6f4a4a", "#256f25", "#25deb9", "#6f25de", "#94b925", "#b9254a", "#4ade25", "#4a006f", "#25006f", "#94de00", "#6fb925", "#259425", "#6f9425", "#944a00", "#25b9b9", "#25de4a", "#00254a", "#94254a", "#4a6f94", "#002500", "#6fdede", "#deb925", "#b9b9de", "#4a4a94", "#004a4a", "#25b994", "#6f6f00", "#b92500", "#b925b9", "#940094", "#2594de", "#4ade4a", "#949400", "#256f6f", "#de00de", "#6fde25", "#4a6fde", "#4a4ab9", "#deb96f", "#6f0025", "#00b925", "#0000b9", "#254a94", "#4a25b9", "#b9004a", "#b9de00", "#6f254a", "#6f2500", "#94b96f", "#25de00", "#b99425", "#b90025", "#0094b9", "#4ab925", "#4ab96f", "#6fde00", "#b9b96f", "#94b9b9", "#de4a6f", "#4a2500", "#de0000", "#4a4a4a", "#259494", "#9400b9", "#b9deb9", "#254a00", "#0000de", "#dede4a", "#94dede", "#94de25", "#4a9494", "#4a94de", "#6fb9b9", "#dede00", "#b9256f", "#de9494", "#009494", "#006f4a", "#94944a", "#4ab900", "#6f6f4a", "#b99494", "#6f004a", "#4a256f", "#00b9de", "#b99400", "#00b96f", "#deb9b9", "#4a6f00", "#000025", "#00006f", "#00de4a", "#b96f94", "#6fb9de", "#946fde", "#deb900", "#004ade", "#254ab9", "#25de6f", "#94deb9", "#b994de", "#004a25", "#94256f", "#250025", "#6f6f6f", "#4a944a", "#4a25de", "#00b94a", "#4a4a25", "#9400de", "#94004a", "#4a94b9", "#94de94", "#6f256f", "#6fb900", "#b9944a", "#de94de", "#944a25", "#6f2594"]
