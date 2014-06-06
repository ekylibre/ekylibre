console.log "?"

String.prototype.camelize = () ->
  array = jQuery.map this.split("_"), (word)->
    word.charAt(0).toUpperCase() + word.slice(1)
  return array.join()

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
          fillOpacity: 0.6
          startColor: '#FFFFAA'
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
      
      console.log "6"
      # this._calculArea()
      
      console.log "7"
      # this._calculChoropleth()
      
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
        
    _calculArea: ->
      if this.options.layers
        $.each this.options.layers, ( index, value ) ->
          $.each value.list, (index, value) ->
            if value.choropleth_value == 'area'
              tmp = value.area.value.split("/")
              value.choropleth_value = Math.round(tmp[0]/tmp[1])

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

    # Round a value with magnitude
    _round: (value) ->
      i = 11
      while (i)
        s = Math.pow(10, (i - 3) * 3)
        break if s <= value
        i--
      return Math.round(value / s) + "nµm KMGTPE"[i]

    _computeChoropleth: (layer) ->
      widget = this
      property = layer.reference
      defaultChoropleth =
        maxValue: layer.data[0][property]
        minValue: layer.data[0][property]
        grades: []
      layer.choropleth = $.extend true, {}, @options.layerDefaults.choropleth, defaultChoropleth, layer.choropleth
      console.log layer.choropleth
      choropleth = layer.choropleth
      $.each layer.data, (index, zone) ->
        if zone[property] > choropleth.maxValue
          choropleth.maxValue = zone[property]
        if zone[property] < choropleth.minValue
          choropleth.minValue = zone[property]
      choropleth.length = choropleth.maxValue - choropleth.minValue
      console.log "Min and max computed"

      start = this._parseColor(choropleth.startColor)
      stop  = this._parseColor(choropleth.stopColor)
      gap =
        red:   Math.round(stop.red   - start.red)
        green: Math.round(stop.green - start.green)
        blue:  Math.round(stop.blue  - start.blue)
      console.log "Gap color computed"
      
      for g in [1..choropleth.levelNumber]
        level = (g - 1.0) / (choropleth.levelNumber - 1.0)
        color = this._toColorString
          red:   start.red   + (gap.red   * level)
          green: start.green + (gap.green * level)       
          blue:  start.blue  + (gap.blue  * level)
        choropleth.grades.push
          color: color,
          min: this._round(choropleth.minValue + (g-1) * choropleth.length / choropleth.levelNumber, 2)
          max: this._round(choropleth.minValue +  g    * choropleth.length / choropleth.levelNumber, 2)
          
      $.each layer.data, (index, zone) ->
        level = 1.0 * (zone[property] - choropleth.minValue) / choropleth.length
        zone.fillColor = widget._toColorString
          red:   start.red   + (gap.red   * level)
          green: start.green + (gap.green * level)       
          blue:  start.blue  + (gap.blue  * level)
        
      console.log "Choropleth computed"
      this

    # _calculChoropleth: () ->
    #   if this.options.layers
    #     widget = this
    #     $.each this.options.layers, ( index, value ) ->
    #       max_value = 0
    #       min_value = 0
    #       choro = false
    #       if value.list[1]['style'] == 'choropleth'
    #         max_value = value.list[1]['choropleth_value']
    #         min_value = value.list[1]['choropleth_value'] 
    #       level_number = 0 
    #       start = ""
    #       end = ""
    #       $.each value.list, (index, value) ->
    #         if value.style == 'choropleth'              
    #           level_number = value.choropleth_level_number
    #           choro = true
    #           start = value.choropleth_start_color
    #           end = value.choropleth_end_color
    #           if value.choropleth_value > max_value
    #             max_value = value.choropleth_value
    #           if value.choropleth_value < min_value
    #             min_value = value.choropleth_value
            
    #       if true # choro
    #         start_red   = parseInt(start.slice(1,3),16)
    #         start_green = parseInt(start.slice(3,5),16)
    #         start_blue  = parseInt(start.slice(5,7),16)
    #         end_red   = parseInt(end.slice(1,3),16)
    #         end_green = parseInt(end.slice(3,5),16)
    #         end_blue  = parseInt(end.slice(5,7),16)
    #         red_gap   = Math.ceil((start_red - end_red)/level_number)
    #         green_gap = Math.ceil((start_green - end_green)/level_number)
    #         blue_gap  = Math.ceil((start_blue - end_blue)/level_number)
            
    #       $.each value.list, (index, value) ->
    #         if value.style == 'choropleth'
    #           value.max_value = max_value
    #           value.min_value = min_value  
    #           colorLevel = Math.ceil(value.choropleth_value/((max_value-min_value)/level_number))
    #           value.level = colorLevel               
    #           red   = start_red - (red_gap*colorLevel)       
    #           green = start_green - (green_gap*colorLevel)       
    #           blue  = start_blue - (blue_gap*colorLevel)       
    #           value.fillColor = "##{widget._toHex(red)}#{widget._toHex(green)}#{widget._toHex(blue)}"
    #   this

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
        backgroundLayer = L.tileLayer.provider(layer.provider_name)
        baseLayers[layer.name] = backgroundLayer
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
          layerGroup = widget[functionName].call(widget, layer, legendControl)
          overlayLayer = L.layerGroup(layerGroup)
          layer.overlay = overlays[layer.name] = overlayLayer
          widget.map.addLayer(overlayLayer)

          group = new L.featureGroup(layerGroup)
          widget.map.fitBounds(group.getBounds())
        else
          console.log "Unknown layer type: #{layer.type}"
        
      @map.on "overlayadd", (event) ->
        console.log "Add legend control..."
        legend = $(legendControl.getContainer())
        legend.children("#legend-#{event.name}").show()
        legend.children(".first").removeClass("first")
        legend.children(":visible:first").addClass("first")
        legend.removeClass("empty")
        return       
        
      @map.on "overlayremove", (event) ->
        console.log "Remove legend control #{event}..."
        legend = $(legendControl.getContainer())
        legend.children("#legend-#{event.name}").hide()
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
      layerGroup = []
      options = $.extend(true, {}, @options.layerDefaults.simple, layer)
      $.each layer.data, (index, zone) ->
        zoneLayer = new L.GeoJSON(zone.shape, {stroke: options.stroke, color: options.color, weight: options.weight, opacity: options.opacity, fill: options.fill, fillColor: options.fillColor, fillOpacity: options.fillOpacity} )
        popup = "#{zone.name}<br/>Area: #{zone.area}"
        zoneLayer.bindPopup(popup)
        layerGroup.push(zoneLayer)
      return layerGroup

    _addChoroplethLayer: (layer, legendControl)->
      this._computeChoropleth(layer)
      layerGroup = []
      options = $.extend(true, {}, @options.layerDefaults.choropleth, layer)
      $.each layer.data, (index, zone) ->            
        zoneLayer = new L.GeoJSON(zone.shape, {stroke: options.stroke, color: options.color, weight: options.weight, opacity: options.opacity, fill: options.fill, fillColor: zone.fillColor, fillOpacity: options.fillOpacity} )
        popup = "#{zone.name}<br/>Area: #{zone.area}"
        zoneLayer.bindPopup(popup)
        layerGroup.push(zoneLayer)
      console.log("Choropleth layer added")

      # Add legend
      legend = legendControl.getContainer()
      console.log(legend)
      html  = "<div class='leaflet-legend-item' id='legend-#{layer.name}'>"
      html += "<h3>#{layer.name}</h3>"
      html += "<div class='leaflet-legend-body leaflet-choropleth-scale'>"
      html += "<span class='min-value'>#{layer.choropleth.grades[0].min}</span>"
      html += "<span class='max-value'>#{layer.choropleth.grades[layer.choropleth.levelNumber - 1].max}</span>"
      html += "<span class='leaflet-choropleth-grades'>"
      $.each layer.choropleth.grades, (index, grade) ->               
        html += "<i class='leaflet-choropleth-grade' style='background-color: #{grade.color}' title='#{grade.min} &ndash; #{grade.max}'></i>"
      html += "</span>"
      html += "</div>"
      html += "</div>"
      legend.innerHTML += html

      return layerGroup

    _addBubblesLayer: (layer, legendControl)->
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
        popup = "#{zone.name} <br> Amount of potassium :  #{Math.round(zone.radius)} grames by square meter"
        zoneLayer.bindPopup(popup)
        layerGroup.push(zoneLayer)   
      return layerGroup

    _addCategoriesLayer: (layer, legendControl)->
      layerGroup = []
      alert "Not implemented"
      return layerGroup
                                
 
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

  $(document).ready ->
    $("*[data-visualization]").each ->
      $(this).visualization()
       
) jQuery


