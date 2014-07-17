# Add sprockets directives below:
#= require core_ext
#= require visualization/color
#= require visualization/choropleth
#= require visualization/bubbles

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
      series: {}
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
          color: "#333333"
          weight: 1
          opacity: 1
          fill: true
          fillColor: "orange"
          fillOpacity: 1
        categories:
          stroke: true
          color: "#333333"
          weight: 1
          opacity: 1
          fill: true
          fillOpacity: 1
        choropleth:
          stroke: true
          color: "#333333"
          weight: 1
          opacity: 1
          fill: true
          fillColor: "blue"
          fillOpacity: 1
          round: 5
          startColor: '#FFFFFF'
          stopColor: '#910000'
          levelNumber: 7
        simple:
          stroke: true
          color: "#333333"
          weight: 1
          opacity: 1
          fill: true
          fillColor: "green"
          fillOpacity: 1
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
      $.extend(true, @options, @element.data("visualization"))

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

    # Retuns data from a serie found with the given name
    _getSerieData: (name) ->
      if @options.series[name]?
        return @options.series[name]
      else
        console.error "Cannot find serie #{name}"
        alert "Cannot find serie #{name}"

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
      baseLayers = {}
      overlays = {}

      for layer, index in @options.backgrounds
        backgroundLayer = L.tileLayer.provider(layer.provider)
        baseLayers[layer.label] = backgroundLayer
        @map.addLayer(backgroundLayer) if index == 0

      for layer in @options.overlays
        overlayLayer = L.tileLayer.provider(layer.provider_name)
        overlays[layer.name] = overlayLayer

      legendControl = new L.control(position: "bottomright")
      legendControl.onAdd = (map) ->
        L.DomUtil.create('div', 'leaflet-legend-control')
      @map.addControl legendControl

      for layer in @options.layers
        if console.group isnt undefined
          console.group "Add layer #{layer.name}..."
        else
          console.log "Add layer #{layer.name}..."
        functionName = "_add#{layer.type.camelize()}Layer"
        if $.isFunction this[functionName]
          options = {} if options is true
          if layerGroup = this[functionName].call(this, layer, legendControl)
            overlayLayer = L.layerGroup(layerGroup)
            overlayLayer.name = layer.name
            layer.overlay = overlays[layer.label] = overlayLayer
            @map.addLayer(overlayLayer)
            group = new L.featureGroup(layerGroup)
            @map.fitBounds(group.getBounds())
          else
            console.warn "Cannot add layer #{layer.type}"
        else
          console.log "Unknown layer type: #{layer.type}"
        console.groupEnd() if console.groupEnd isnt undefined

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
      layerGroup = []
      options = $.extend(true, {}, @options.layerDefaults.simple, layer)
      for zone in this._getSerieData(layer.serie)
        zoneLayer = new L.GeoJSON(zone.shape, options)
        this._bindPopup(zoneLayer, zone)
        layerGroup.push(zoneLayer)
      return layerGroup

    _addChoroplethLayer: (layer, legendControl)->
      data = this._getSerieData(layer.serie)
      options = $.extend true, {}, @options.layerDefaults.choropleth, layer
      choropleth = new visualization.Choropleth(layer, data, options)
      unless choropleth.valid()
        return false

      layerGroup = choropleth.buildLayerGroup(this, options)
      console.log("Choropleth layer added")

      # Add legend
      legend = legendControl.getContainer()
      legend.innerHTML += choropleth.buildLegend()

      return layerGroup

    _addBubblesLayer: (layer, legendControl)->
      data = this._getSerieData(layer.serie)
      options = $.extend true, {}, @options.layerDefaults.bubbles, layer
      bubbles = new visualization.Bubbles(layer, data, options)
      return false unless bubbles.valid()

      layerGroup = bubbles.buildLayerGroup(this, options)
      console.log("Bubbles layer added")

      # Add legend
      legend = legendControl.getContainer()
      legend.innerHTML += bubbles.buildLegend()

      return layerGroup

    _addCategoriesLayer: (layer, legendControl)->
      data = this._getSerieData(layer.serie)
      options = $.extend true, {}, @options.layerDefaults.categories, layer
      categories = new visualization.Categories(layer, data, options)
      return false unless categories.valid()

      layerGroup = categories.buildLayerGroup(this, options)
      console.log("Categories layer added")

      # Add legend
      legend = legendControl.getContainer()
      legend.innerHTML += categories.buildLegend()

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


