console.log "?"

String.prototype.camelize = () ->
  array = jQuery.map this.split("_"), (word)->
    word.charAt(0).toUpperCase() + word.slice(1)
  return array.join()
  
String.prototype.repeat = (count) ->
  return new Array(count + 1).join(this)
  
Math.magnitude = (number, step = 1) ->
  value = Math.abs(number)
  power = 0
  if value > 1
    while Math.pow(10, power + step) < value
      power += step
  else
    while Math.pow(10, power - step) > value
      power -= step
  mag = Math.pow(10, power)
  result =
    power: power
    magnitude: mag
    base: number / mag

Math.round2 = (number, round = 1) ->
  return round * Math.round(number / round)

Math.humanize = (value, power = 0) ->
  return Math.round(value)
  # return Math.round(value / Math.pow(10, power)) + "e#{power}"
  size = Math.round(power / 3)
  return Math.round(value / Math.pow(10, 3 * size)) + "pnµm KMGTPE"[size + 4]

Math.ceil2 = (number, round = 1) ->
  return round * Math.ceil(number / round)

Math.floor2 = (number, round = 1) ->
  return round * Math.floor(number / round)
 

(($) ->
  "use strict"
 
  $.widget "ui.visualization",
    options:
      box:
        height: 400
        width: null
      backgrounds: {}
      overlays: {}
      controls: {}
      controlDefaults:
        fullscreen:
          position: 'topleft'
        geocoder:
          collapsed: true,
          position: 'topright',
          text: 'Locate',
          bounds: null, 
          email: null       
        layerSelector:
          collapsed: true,
          position: 'topright',
          autoZIndex: true
        scale:
          position: 'bottomleft'
          maxWidth: 200
          metric: true
          imperial: false
          updateWhenIdle: false        
        zoom:
          position: 'topleft'
          zoomInText: ''
          zoomInTitle: 'Zoom In'
          zoomOutText: ''
          zoomOutTitle: 'Zoom Out'
      layers: {}
      layerDefaults:
        bubbles:
          stroke: true
          color: "black"
          weight: 1
          opacity: 1
          fill: true
          fillColor: "orange"
          fillOpacity: 0.6
        choropleth:
          stroke: true
          color: "black"
          weight: 1
          opacity: 1
          fill: true
          fillColor: "blue"
          fillOpacity: 0.8
          round: 5
          startColor: '#EEEEE0'
          stopColor: '#910000'
          levelNumber: 7   
        simple:
          stroke: true
          color: "black"
          weight: 1
          opacity: 1
          fill: true
          fillColor: "green"
          fillOpacity: 0.6
      map:
        maxZoom: 18
        minZoom:2
        zoomControl: false
        attributionControl: false      
      view: 
        center:[]
        zoom : 13
                
    _create: ->     
      console.log "1"
      $.extend(true, this.options, this.element.data("visualization"))

      console.log "2"
      @mapElement = $("<div>", class: "map").insertAfter(@element)

      console.log "3"
      @map = L.map(@mapElement[0], @options.map)

      console.log "4"
      this._resize()

      console.log "5"
      this._refreshView()
      
      console.log "8"
      this._refreshControls()
           
      console.log "9"
 
    _destroy: ->
      @mapElement.remove()
            
    zoom: (zoom) ->
      return @map.getZoom() unless zoom?
      this.options.view.zoom = zoom
      this._refreshZoom()
 
    height: (height) ->
      return this.options.box.height unless height?
      this.options.view.box.height = height
      this._resize()
 
    _resize: -> 
      if this.options.box?
        if this.options.box.height?
          @mapElement.height this.options.box.height
        if this.options.box.width?
          @mapElement.width this.options.box.width
        this._trigger "resize"
        
    # Returns hexadecimal value of given integer on 2 digits.
    _toHex: (integer) ->
      hex = Math.round(integer).toString(16)
      if integer <= 0
        return "00"
      else if integer < 16
        return "0" + hex
      else if integer > 255
        return "FF"
      else
        return hex

    # Retuns an object with rgb properties
    _parseColor: (color) ->
      value =
        red:   parseInt(color.slice(1,3), 16)
        green: parseInt(color.slice(3,5), 16)
        blue:  parseInt(color.slice(5,7), 16)
      return value

    _toColorString: (color) ->
      return "##{this._toHex(color.red)}#{this._toHex(color.green)}#{this._toHex(color.blue)}"

    _computeChoropleth: (layer) ->
      widget = this
      property = layer.reference
      defaultChoropleth =
        maxValue: layer.data[0][property]
        minValue: layer.data[0][property]
        grades: []
      layer.choropleth = $.extend true, {}, @options.layerDefaults.choropleth, defaultChoropleth, layer.choropleth
      choropleth = layer.choropleth
      $.each layer.data, (index, zone) ->
        if zone[property] > choropleth.maxValue
          choropleth.maxValue = zone[property]
        if zone[property] < choropleth.minValue
          choropleth.minValue = zone[property]

      # Simplify values
      maxMagnitude = Math.magnitude(choropleth.maxValue)
      minMagnitude = Math.magnitude(choropleth.minValue)
      ref = minMagnitude
      if maxMagnitude.power > minMagnitude.power
        ref = maxMagnitude
      choropleth.power = ref.power
      mag = ref.magnitude
      mag = mag / 10 if mag >= 100
      choropleth.maxValue = Math.ceil2(choropleth.maxValue,  mag * choropleth.round)
      choropleth.minValue = Math.floor2(choropleth.minValue, mag * choropleth.round)
      choropleth.length = choropleth.maxValue - choropleth.minValue

      if choropleth.length == 0
        console.log "Length is null"
        return false
      
      if choropleth.levelNumber > choropleth.length and choropleth.length > 2
        choropleth.levelNumber = choropleth.length
      console.log "Min (#{choropleth.minValue}) and max (#{choropleth.maxValue}) computed"

      start = this._parseColor(choropleth.startColor)
      stop  = this._parseColor(choropleth.stopColor)
      
      for g in [1..choropleth.levelNumber]
        level = (g - 1.0) / (choropleth.levelNumber - 1.0)
        grade = 
          color: this._toColorString
            red:   start.red   + (Math.round(stop.red   - start.red)   * level)
            green: start.green + (Math.round(stop.green - start.green) * level)       
            blue:  start.blue  + (Math.round(stop.blue  - start.blue)  * level)
          min: choropleth.minValue + (g-1) * choropleth.length / choropleth.levelNumber
          max: choropleth.minValue +  g    * choropleth.length / choropleth.levelNumber
        grade.minLabel = Math.humanize(grade.min, choropleth.power)
        grade.maxLabel = Math.humanize(grade.max, choropleth.power)
        choropleth.grades.push grade
      console.log "Grades computed"
          
      $.each layer.data, (index, zone) ->
        level = Math.round(choropleth.levelNumber * (zone[property] - choropleth.minValue) / choropleth.length)
        level = choropleth.levelNumber - 1 if level >= choropleth.levelNumber
        level = 0 if level < 0
        zone.fillColor = choropleth.grades[level].color
        
      console.log "Choropleth computed"
      true

    # Displays all given controls
    _refreshControls: ->
      console.log "Refresh controls..."
      return false unless @options.controls?
      widget = this
      for name, options of @options.controls
        console.log "Add control #{name}..."
        if options isnt false
          functionName = "_add#{name.camelize()}Control"
          if $.isFunction widget[functionName]
            options = {} if options is true
            widget[functionName].call(widget, options)
          else
            console.log "Unknown control: #{name}"

    _addFullscreenControl: (options) ->
      options = $.extend true, {}, @options.controlDefaults.fullscreen, options
      control = new L.Control.FullScreen options
      @map.addControl control

    _addGeocoderControl: (options) ->
      options = $.extend true, {}, @options.controlDefaults.geocoder, options
      control = new L.Control.OSMGeocoder options
      @map.addControl control

    _addLayerSelectorControl: (options) ->
      widget = this
      baseLayers = {}
      overlays = {}
      
      $.each @options.backgrounds, (index, layer) -> 
        backgroundLayer = L.tileLayer.provider(layer.provider)
        baseLayers[layer.label] = backgroundLayer
        widget.map.addLayer(backgroundLayer) if index == 0
      
      $.each @options.overlays, (index, layer) -> 
        overlayLayer = L.tileLayer.provider(layer.provider_name)
        overlays[layer.name] = overlayLayer

      legendControl = new L.control(position: "bottomright")
      legendControl.onAdd = (map) ->
        L.DomUtil.create('div', 'leaflet-legend-control')
      @map.addControl legendControl
        
      $.each @options.layers, (index, layer) ->
        console.log "Add layer..."
        functionName = "_add#{layer.type.camelize()}Layer"
        if $.isFunction widget[functionName]
          options = {} if options is true
          if layerGroup = widget[functionName].call(widget, layer, legendControl)
            overlayLayer = L.layerGroup(layerGroup)
            overlayLayer.name = layer.name            
            layer.overlay = overlays[layer.label] = overlayLayer
            widget.map.addLayer(overlayLayer)
            group = new L.featureGroup(layerGroup)
            widget.map.fitBounds(group.getBounds())
        else
          console.log "Unknown layer type: #{layer.type}"
        
      @map.on "overlayadd", (event) ->
        console.log "Add legend control..."
        legend = $(legendControl.getContainer())
        legend.children("#legend-#{event.layer.name}").show()
        legend.children(".first").removeClass("first")
        legend.children(":visible:first").addClass("first")
        legend.removeClass("empty")
        return       
        
      @map.on "overlayremove", (event) ->
        console.log "Remove legend control..."
        legend = $(legendControl.getContainer())
        legend.children("#legend-#{event.layer.name}").hide()
        legend.children(".first").removeClass("first")
        legend.children(":visible:first").addClass("first")
        legend.addClass("empty") if legend.children(":visible").length <= 0
        return                                                 

      control = new L.Control.Layers(baseLayers, overlays, @options.controlDefaults.layerSelector)
      @map.addControl control

    _addScaleControl: (options) ->
      options = $.extend true, {}, @options.controlDefaults.scale, options
      control = new L.Control.Scale options
      @map.addControl control

    _addZoomControl: (options) ->
      options = $.extend true, {}, @options.controlDefaults.zoom, options
      control = new L.Control.Zoom options
      @map.addControl control

    _addSimpleLayer: (layer, legendControl)->
      widget = this
      layerGroup = []
      options = $.extend(true, {}, @options.layerDefaults.simple, layer)
      $.each layer.data, (index, zone) ->
        zoneLayer = new L.GeoJSON(zone.shape, {stroke: options.stroke, color: options.color, weight: options.weight, opacity: options.opacity, fill: options.fill, fillColor: options.fillColor, fillOpacity: options.fillOpacity} )
        widget._bindPopup(zoneLayer, zone)
        layerGroup.push(zoneLayer)
      return layerGroup

    _addChoroplethLayer: (layer, legendControl)->
      widget = this
      return false unless this._computeChoropleth(layer)
      layerGroup = []
      options = $.extend(true, {}, @options.layerDefaults.choropleth, layer)
      $.each layer.data, (index, zone) ->            
        zoneLayer = new L.GeoJSON(zone.shape, {stroke: options.stroke, color: options.color, weight: options.weight, opacity: options.opacity, fill: options.fill, fillColor: zone.fillColor, fillOpacity: options.fillOpacity} )
        widget._bindPopup(zoneLayer, zone)
        layerGroup.push(zoneLayer)
      console.log("Choropleth layer added")

      # Add legend
      legend = legendControl.getContainer()
      console.log(legend)
      html  = "<div class='leaflet-legend-item' id='legend-#{layer.name}'>"
      html += "<h3>#{layer.label}</h3>"
      html += "<div class='leaflet-legend-body leaflet-choropleth-scale'>"
      html += "<span class='min-value'>#{layer.choropleth.grades[0].minLabel}</span>"
      html += "<span class='max-value'>#{layer.choropleth.grades[layer.choropleth.levelNumber - 1].maxLabel}</span>"
      html += "<span class='leaflet-choropleth-grades'>"
      $.each layer.choropleth.grades, (index, grade) ->               
        html += "<i class='leaflet-choropleth-grade' style='width: #{100 / layer.choropleth.levelNumber}%; background-color: #{grade.color}' title='#{grade.minLabel} ~ #{grade.maxLabel}'></i>"
      html += "</span>"
      html += "</div>"
      html += "</div>"
      legend.innerHTML += html

      return layerGroup

    _addBubblesLayer: (layer, legendControl)->
      widget = this
      layerGroup = []
      alert "Not implemented"
      return layerGroup
      options = $.extend(true, {}, @options.layerDefaults.bubbles, layer)
      $.each layer.data, (index, zone) ->            
        if zone.radius > max_bubble_zone
          bubble_legend_color = zone.fillColor
          max_bubble_value = zone.radius
          max_bubble_value_digits = (max_bubble_value.toString().length)-1
              
        zoneLayer = new L.Circle(zone.center, zone.radius, {stroke: layer.stroke, color: layer.color, weight: layer.weight, opacity: layer.opacity, fill: layer.fill, fillColor: layer.fillColor, fillOpacity: layer.fillOpacity} )
        widget._bindPopup(zoneLayer, zone)
        layerGroup.push(zoneLayer)
      return layerGroup

    _addCategoriesLayer: (layer, legendControl)->
      layerGroup = []
      alert "Not implemented"
      return layerGroup

    # Build a popup from given parameters. For now it only uses popup attribute of
    # a zone. After it will use a global template for all zone by default which can be
    # overriden with a local popup
    _bindPopup: (layer, zone) ->
      return unless zone.popup?
      popup = ""
      for block in zone.popup
        popup += "<div class='popup-#{block.type}'>"
        if block.label?
          popup += "<span class='popup-block-label'>#{block.label}</span>"
        if block.content?
          popup += "<span class='popup-block-content'>#{block.content}</span>"         
        else if block.value?
          popup += "<span class='popup-block-value'>#{block.value}</span>"
        popup += "</div>"
      layer.bindPopup(popup)
      return layer
                                
 
    _refreshView: (view) ->
      this._setDefaultView()
      # else if view.center?
      #   if this.options.layers?

      #   if view.zoom?
      #     @map.setView(center, view.zoom)
      #   else
      #     @map.setView(center, zoom)
      # this
 
    _setDefaultView: ->
      @map.fitWorld()
      @map.setZoom 6
           
    _refreshZoom: ->
      if this.options.view.zoom?
        @map.setZoom(this.options.view.zoom)

  $.loadVisualizations = ->
    $("*[data-visualization]").each ->
      $(this).visualization()
    return

  $(document).ready $.loadVisualizations
  $(document).on "page:load cocoon:after-insert cell:load", $.loadVisualizations

) jQuery


