# Add sprockets directives below:
#= require core_ext
#= require visualization/color
#= require_self
#= require visualization/band
#= require visualization/bubbles
#= require visualization/categories
#= require visualization/choropleth
#= require visualization/heatmap
#= require visualization/path
#= require visualization/paths
#= require visualization/points
#= require visualization/point_group
#= require visualization/simple

((V, $) ->
  "use strict"

  V.layer = (layer, data, options) ->
    @layerTypes ?= {}
    if type = @layerTypes[layer.type]
      return new type(layer, data, options)
    else
      console.warn "Invalid layer type: #{layer.type}"
      return null

  V.registerLayerType = (name, klass) ->
    @layerTypes ?= {}
    @layerTypes[name] = klass

  # Generated colors in ruby
  # $ p = Proc.new{[37 * rand(7), 255].min.to_i.to_s(16).rjust(2, "0")}
  # $ (1..300).collect{|x| "##{p[]}#{p[]}#{p[]}"}.uniq
  V.colors = ["#00de00", "#6f006f", "#4ade94", "#004ab9", "#de6f4a", "#b9b925", "#00b994", "#25946f", "#de00b9", "#94006f", "#de6f94", "#252594", "#dede94", "#4a2594", "#940000", "#deb9de", "#00b9b9", "#00de94", "#25254a", "#6fde6f", "#4a0094", "#256f4a", "#6f4a25", "#4a4a00", "#b9006f", "#4a6f25", "#6f946f", "#009425", "#6f4ade", "#2525de", "#b9946f", "#b9b994", "#b9de94", "#de256f", "#b900b9", "#4a4a6f", "#4a2525", "#006fde", "#940025", "#250094", "#b900de", "#4ab9b9", "#00004a", "#6f6fde", "#256fde", "#b92594", "#6f944a", "#6f6f25", "#4ab9de", "#de2525", "#2525b9", "#944a94", "#b94a94", "#946f94", "#b94a6f", "#000094", "#4a6f6f", "#006f00", "#946f4a", "#00256f", "#6f4a6f", "#de6fb9", "#6fdeb9", "#de6f00", "#94b94a", "#94b994", "#6f6fb9", "#b925de", "#de2594", "#dede25", "#6f4a94", "#946f6f", "#de25de", "#b92525", "#6fde94", "#254a25", "#4adeb9", "#00deb9", "#b9b9b9", "#6f4a4a", "#256f25", "#25deb9", "#6f25de", "#94b925", "#b9254a", "#4ade25", "#4a006f", "#25006f", "#94de00", "#6fb925", "#259425", "#6f9425", "#944a00", "#25b9b9", "#25de4a", "#00254a", "#94254a", "#4a6f94", "#002500", "#6fdede", "#deb925", "#b9b9de", "#4a4a94", "#004a4a", "#25b994", "#6f6f00", "#b92500", "#b925b9", "#940094", "#2594de", "#4ade4a", "#949400", "#256f6f", "#de00de", "#6fde25", "#4a6fde", "#4a4ab9", "#deb96f", "#6f0025", "#00b925", "#0000b9", "#254a94", "#4a25b9", "#b9004a", "#b9de00", "#6f254a", "#6f2500", "#94b96f", "#25de00", "#b99425", "#b90025", "#0094b9", "#4ab925", "#4ab96f", "#6fde00", "#b9b96f", "#94b9b9", "#de4a6f", "#4a2500", "#de0000", "#4a4a4a", "#259494", "#9400b9", "#b9deb9", "#254a00", "#0000de", "#dede4a", "#94dede", "#94de25", "#4a9494", "#4a94de", "#6fb9b9", "#dede00", "#b9256f", "#de9494", "#009494", "#006f4a", "#94944a", "#4ab900", "#6f6f4a", "#b99494", "#6f004a", "#4a256f", "#00b9de", "#b99400", "#00b96f", "#deb9b9", "#4a6f00", "#000025", "#00006f", "#00de4a", "#b96f94", "#6fb9de", "#946fde", "#deb900", "#004ade", "#254ab9", "#25de6f", "#94deb9", "#b994de", "#004a25", "#94256f", "#250025", "#6f6f6f", "#4a944a", "#4a25de", "#00b94a", "#4a4a25", "#9400de", "#94004a", "#4a94b9", "#94de94", "#6f256f", "#6fb900", "#b9944a", "#de94de", "#944a25", "#6f2594"]

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
          title: I18n.t("#{I18n.rootKey}.leaflet.fullscreenTitle")
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
          zoomInTitle: I18n.t("#{I18n.rootKey}.leaflet.zoomInTitle")
          zoomOutText: ''
          zoomOutTitle: I18n.t("#{I18n.rootKey}.leaflet.zoomOutTitle")
      layers: {}
      layerDefaults:
        band:
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
        paths:
          stroke: true
          color: "#333333"
          weight: 2
          opacity: 0.2
          fill: true
          fillOpacity: 1
        path:
          stroke: true
          color: "#333333"
          weight: 3
          opacity: 1
          fill: true
          fillOpacity: 1
          fillColor: "#333333"
          radius: 3
        points:
          stroke: true
          color: "#333333"
          weight: 2
          opacity: 1
          fill: true
          fillOpacity: 1
          radius: 5
        point_group:
          stroke: true
          color: "#333333"
          weight: 2
          opacity: 1
          fill: true
          fillOpacity: 1
          radius: 5
      map:
        scrollWheelZoom: false
        zoomControl: false
        attributionControl: true
        setDefaultBackground: false
        setDefaultOverlay: false
        dragging: true
        touchZoom: true
        doubleClickZoom: true
        boxZoom: true
        tap: true
      view:
        center:[]
        zoom : 13
        maxZoom: 25
        minZoom:2
      colors: V.colors

    _create: ->
      $.extend(true, @options, @element.data("visualization"))
      @mapElement = $("<div>", class: "map").appendTo(@element)

      @map = L.map(@mapElement[0], @options.map)
      @layers = []

      if @options.map.setDefaultBackground
        opts = {}
        opts['attribution'] = @options.backgrounds.attribution if @options.backgrounds.attribution?
        opts['minZoom'] = @options.backgrounds.minZoom || @options.view.minZoom
        opts['maxZoom'] = @options.backgrounds.maxZoom || @options.view.maxZoom
        opts['subdomains'] = @options.backgrounds.subdomains if @options.backgrounds.subdomains?
        opts['tms'] = true if @options.backgrounds.tms

        backgroundLayer = L.tileLayer(@options.backgrounds.url, opts)
        backgroundLayer.addTo @map

      if @options.map.setDefaultOverlay
        opts = {}
        opts['attribution'] = @options.overlays.attribution if @options.overlays.attribution?
        opts['minZoom'] = @options.overlays.minZoom || @options.view.minZoom
        opts['maxZoom'] = @options.overlays.maxZoom || @options.view.maxZoom
        opts['subdomains'] = @options.overlays.subdomains if @options.overlays.subdomains?
        opts['opacity'] = (@options.overlays.opacity / 100).toFixed(1) if @options.overlays.opacity? and !isNaN(@options.overlays.opacity)
        opts['tms'] = true if @options.overlays.tms

        OverlayLayer = L.tileLayer(@options.overlays.url, opts)
        OverlayLayer.addTo @map

      @ghostLabelCluster = L.ghostLabelCluster(type: 'number', innerClassName: 'leaflet-ghost-label-collapsed')
      @ghostLabelCluster.addTo @map

      @layersScheduler = L.layersScheduler()
      @layersScheduler.addTo @map

      this._resize()
      this._refreshView()
      this._refreshControls()

    _destroy: ->
      @mapElement.remove()

    zoom: (zoom) ->
      return @map.getZoom() unless zoom?
      @options.view.zoom = zoom
      this._refreshZoom()

    height: (height) ->
      return @options.box.height unless height?
      @options.view.box.height = height
      this._resize()

    rebuild: ->
      this._destroy()
      this._create()

    layrs: ->
      return @layers

    mappo: ->
      return @map

    mappoElement: ->
      return @mapElement

    _resize: ->
      if @options.box?
        if @options.box.height?
          @mapElement.height @options.box.height
        if @options.box.width?
          @mapElement.width @options.box.width
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
      console.log "Refresh controls...", @options.controls
      unless @options and @options.controls?
        console.log "No controls..."
        return false
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
      @map.on "enterFullscreen", (e) =>
        @map.scrollWheelZoom.enable();

      @map.on "exitFullscreen", (e) =>
        @map.scrollWheelZoom.disable();


    _addGeocoderControl: (options) ->
      options = $.extend true, {}, @options.controlDefaults.geocoder, options
      control = new L.Control.OSMGeocoder options
      @map.addControl control

    _addLayerSelectorControl: (options) ->
      baseLayers = {}
      overlays = {}

      if @options.backgrounds.length > 0
        for layer, index in @options.backgrounds
          opts = {}
          opts['attribution'] = layer.attribution if layer.attribution?
          opts['minZoom'] = layer.minZoom || @options.view.minZoom
          opts['maxZoom'] = layer.maxZoom || @options.view.maxZoom
          opts['subdomains'] = layer.subdomains if layer.subdomains?
          opts['tms'] = true if layer.tms

          backgroundLayer = L.tileLayer(layer.url, opts)
          baseLayers[layer.name] = backgroundLayer
          @map.addLayer(backgroundLayer) if layer.byDefault
      else
        # no backgrounds, set defaults
        backgrounds = ['OpenStreetMap.HOT',"OpenStreetMap.Mapnik", "Thunderforest.Landscape", "Esri.WorldImagery"]

        baseLayers = {}
        for layer, index in backgrounds
          backgroundLayer = L.tileLayer.provider(layer)
          baseLayers[layer] = backgroundLayer
          @map.addLayer(backgroundLayer) if index == 0
        @map.fitWorld( { maxZoom: @options.view.maxZoom } )


      for layer in @options.overlays
        opts = {}
        opts['attribution'] = layer.attribution if layer.attribution?
        opts['minZoom'] = layer.minZoom || @options.view.minZoom
        opts['maxZoom'] = layer.maxZoom || @options.view.maxZoom
        opts['subdomains'] = layer.subdomains if layer.subdomains?
        opts['opacity'] = (layer.opacity / 100).toFixed(1) if layer.opacity? and !isNaN(layer.opacity)
        opts['tms'] = true if layer.tms

        overlays[layer.name] = L.tileLayer(layer.url, opts)

      legendControl = new L.control(position: "bottomright")
      legendControl.onAdd = (map) ->
        L.DomUtil.create('div', 'leaflet-legend-control')
      @map.addControl legendControl

      $('.leaflet-legend-control').on 'click', () ->
        $(this).find('#legend-activity').toggleClass('minified')


      for layer in @options.layers
        if console.group isnt undefined
          console.group "Add layer #{layer.name} (#{layer.type})..."
        else
          console.log "Add layer #{layer.name}..."
        options = {} if options is true

        data = this._getSerieData(layer.serie)
        options = $.extend true, {}, @options.layerDefaults[layer.type], layer, parent: this
        renderedLayer = V.layer(layer, data, options)
        if renderedLayer and renderedLayer.valid()
          # Build layer group
          layerGroup = renderedLayer.buildLayerGroup(this, options)
          console.log("#{layer.name} layer rendered", layerGroup)
          # Add layer overlay
          overlayLayer = L.layerGroup(layerGroup)
          overlayLayer.name = layer.name
          @layers.push layer
          layer.overlay = overlays[layer.label] = overlayLayer
          @map.addLayer(overlayLayer)
          @layersScheduler.insert overlayLayer._leaflet_id
          console.log("#{layer.name} layer added")
          try
            group = new L.featureGroup(layerGroup)
            bounds = group.getBounds()
            @map.fitBounds(bounds)
            if bounds.getNorthEast().equals bounds.getSouthWest()
              @map.setZoom 18
          # Add legend
          legend = legendControl.getContainer()
          legend.innerHTML += renderedLayer.buildLegend()
        else
          console.warn "Cannot add layer #{layer.type}"

        console.groupEnd() if console.groupEnd isnt undefined

      @map.on "overlayadd", (event) =>
        @layersScheduler.schedule event.layer
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
      if @options.view.center.length > 0
        @map.setView(@options.view.center, @options.view.zoom)

    _setDefaultView: ->
      @map.fitWorld()
      @map.setZoom 6

    _refreshZoom: ->
      if @options.view.zoom?
        @map.setZoom(@options.view.zoom)

  $.loadVisualizations = ->
    $("*[data-visualization]").each ->
      $(this).visualization()
    $(".refresh-locations[data-visualization]").each ->
      refreshSensors($(this))
    return

  # Needed to easily write setTimeout in CoffeeScript
  delay = (time, method) -> setTimeout method, time

  refreshSensors = (mapElement) ->
    console.log "Test"
    unless mapElement.data("refreshTimeout")?
      console.log "Setting timeout"
      timeoutId = delay 10000, -> updateSensorLocations(mapElement)
      mapElement.data("refreshTimeout", timeoutId)

  updateSensorLocations = (mapElement) ->
    sensorLayer = $(mapElement.visualization("layrs")).filter(-> this.name == "sensors")[0]
    layers = sensorLayer.overlay._layers
    layer_keys = Object.keys(sensorLayer.overlay._layers)
    marker_keys = $(layer_keys).filter (index) -> layers[layer_keys[index]].sensorId
    shadow_keys = $(layer_keys).filter (index) -> layers[layer_keys[index]].markerSensorId
    markers = $.map marker_keys, (element, index) -> layers[element]
    shadows = $.map shadow_keys, (element, index) -> layers[element]
    $.get "/backend/sensors/last_locations", (data) ->
      $(Object.keys(data)).each (index, sensorId) ->
        marker = (marker for marker in markers when marker.sensorId == parseInt(sensorId))[0]
        shadow = (shadow for shadow in shadows when shadow.markerSensorId == parseInt(sensorId))[0]
        newPos = new L.LatLng(data[sensorId].coordinates[1], data[sensorId].coordinates[0])
        if marker? && shadow?
          unless marker.getLatLng().equals(newPos)
            marker.setLatLng(newPos)
            shadow.setLatLng(newPos)
    console.log "Updated markers positions"
    timeoutId = delay 10000, -> updateSensorLocations(mapElement)
    clearTimeout mapElement.data("refreshTimeout")
    mapElement.data("refreshTimeout", timeoutId)

  $(document).ready $.loadVisualizations
  $(document).on "page:load cocoon:after-insert cell:load dialog:show", $.loadVisualizations

) visualization, jQuery


