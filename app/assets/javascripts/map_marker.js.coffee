(($) ->
  "use strict"

  $.widget "ui.mapmarker",
    options:
      box:
        height: 400
        width: null
      background: {}
      marker: null
      view: 'auto'
      controls:
        zoom:
          position: "topleft"
          zoomInText: ""
          zoomOutText: ""
        scale:
          position: "bottomright"
          imperial: false
          maxWidth: 200

    _create: ->
      this.oldElementType = @element.attr "type"
      @element.attr "type", "hidden"

      $.extend(true, @options, @element.data("map-marker"))

      @mapElement = $("<div>", class: "map")
        .insertAfter(@element)
      @map = L.map(@mapElement[0],
        maxZoom: 25
        zoomControl: false
        attributionControl: true
      )

      this._resize()
      # console.log "resized"
      this._refreshBackgroundLayer()
      # console.log "backgrounded"
      this._refreshMarkerLayerGroup()
      # console.log "edited"
      this._refreshView()
      # console.log "viewed"
      this._refreshControls()
      # console.log "controlled"

    _destroy: ->
      @element.attr this.oldElementType
      @mapElement.remove()

    background: (background) ->
      return @options.background unless background?
      @options.background = background
      this._refreshBackgroundLayer()

    edit: (geojson) ->
      return @options.edit unless geojson?
      @options.edit = geojson
      this._refreshEditionLayerGroup()

    view: (view) ->
      return @options.view unless view?
      @options.view = view
      this._refreshView()

    zoom: (zoom) ->
      return @map.getZoom() unless zoom?
      @options.view.zoom = zoom
      this._refreshZoom()

    height: (height) ->
      return @options.box.height() unless height?
      @options.view.box.height = height
      this._resize()

    _resize: ->
      if @options.box?
        if @options.box.height?
          @mapElement.height @options.box.height
        if @options.box.width?
          @mapElement.width @options.box.width
        this._trigger "resize"

    _refreshBackgroundLayer: ->
      if @backgroundLayer?
        @map.removeLayer(@backgroundLayer)
      if @options.background?
        if @options.background.constructor.name is "Object"
          @backgroundLayer = L.tileLayer(@options.background.url)
          @backgroundLayer.addTo @map
        if this.options.background.constructor.name is "Array"
          if this.options.background.length > 0
            baseLayers = {}
            for layer, index in @options.background
              opts = {}
              opts['attribution'] = layer.attribution if layer.attribution?
              opts['minZoom'] = layer.minZoom if layer.minZoom?
              opts['maxZoom'] = layer.maxZoom if layer.maxZoom?
              opts['subdomains'] = layer.subdomains if layer.subdomains?
              opts['tms'] = true if layer.tms

              backgroundLayer = L.tileLayer(layer.url, opts)
              baseLayers[layer.name] = backgroundLayer
              @map.addLayer(backgroundLayer) if layer.byDefault
          else
            # no backgrounds, set defaults
            back = ['OpenStreetMap.HOT',"OpenStreetMap.Mapnik", "Thunderforest.Landscape", "Esri.WorldImagery"]

            baseLayers = {}
            for layer, index in back
              backgroundLayer = L.tileLayer.provider(layer)
              baseLayers[layer] = backgroundLayer
              @map.addLayer(backgroundLayer) if index == 0

          @layerSelector = new L.Control.Layers(baseLayers)
          @map.addControl  @layerSelector
        else
          console.log "How to set background with #{@options.background}?"
          console.log @options.background
      this

    _refreshMarkerLayerGroup: ->
      if @marker?
        @map.removeLayer @marker
      console.log @options.marker
      @marker = L.marker @options.marker,
        draggable: true
        riseOnHover: true
      widget = this
      @marker.on "dragend", (e) ->
        widget._saveUpdates()
      @marker.addTo @map
      this._saveUpdates()
      this

    _refreshView: (view) ->
      view ?= @options.view
      if view is 'auto'
        try
          this._refreshView('show')
        catch
          try
            this._refreshView('edit')
          catch
            this._setDefaultView()
      else if view is 'edit' or view is 'show'
        @map.fitBounds @marker.getLayers()[0].getBounds()
      else if view is 'default'
        this._setDefaultView()
      else if view.center?
        center = L.latLng(view.center[0], view.center[1])
        if view.zoom?
          @map.setView(center, view.zoom)
        else
          @map.setView(center, 18)
      else if view.bounds?
        @map.fitBounds(view.bounds)
      else
        console.log "How to set view with #{view}?"
        console.log view
      this

    _setDefaultView: ->
      @map.fitWorld()
      @map.setZoom 18

    _refreshZoom: ->
      if @options.view.zoom?
        @map.setZoom(@options.view.zoom)

    _refreshControls: ->
      if @controls?
        for name, control of @controls
          @map.removeControl(control)
      @controls = {}
      unless @options.controls.zoom is false
        @controls.zoom = new L.Control.Zoom(@options.controls.zoom)
        @map.addControl @controls.zoom
      unless @options.controls.fullscreen is false
        @controls.fullscreen = new L.Control.FullScreen(@options.controls.fullscreen)
        @map.addControl @controls.fullscreen
      unless @options.controls.scale is false
        @controls.scale = new L.Control.Scale(@options.controls.scale)
        @map.addControl @controls.scale

    _saveUpdates: ->
      if @marker?
        console.log @marker
        @element.val JSON.stringify(@marker.toGeoJSON())
      true

  $.loadMapMarker = ->
    $("*[data-map-marker]").each ->
      $(this).mapmarker()
    return

  $(document).ready $.loadMapMarker
  $(document).on "page:load cocoon:after-insert cell:load dialog:show", $.loadMapMarker

) jQuery
