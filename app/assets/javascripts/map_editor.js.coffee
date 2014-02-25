(($) ->
  "use strict"

  $.widget "ui.mapeditor",
    options:
      box:
        height: 400
        width: null
      back: "OpenStreetMap.HOT"
      show: null
      edit: null
      change: null
      view: 'auto'
      controls:
        scale:
          imperial: false
          maxWidth: 200

    _create: ->
      this.oldElementType = this.element.attr "type"
      this.element.attr "type", "hidden"
      this.mapElement = $("<div>", class: "map")
        .after(this.element)
      this.map = L.map(this.mapElement[0],
        maxZoom: 25
        zoomControl: false
        attributionControl: false 
      )
      $.extend(true, this.options, this.element.data("map-editor"))
      this.map.on "draw:created", (e) ->
        this.editionLayerGroup.addLayer e.layer
        this.element.val JSON.stringify(this.map.editionLayerGroup.toGeoJSON())
        return

      this.map.on "draw:edited", (e) ->
        this.element.val JSON.stringify(this.map.editionLayerGroup.toGeoJSON())
        return

      this._resize()
      this._refreshBackgroundLayer()
      this._refreshReferenceLayerGroup()
      this._refreshEditionLayerGroup()
     
    _destroy: ->
      this.element.attr this.oldElementType
      this.mapElement.remove()
      
    back: (back) ->
      return this.options.back unless back?
      this.options.back = back
      this._refreshBackgroundLayer()

    show: (geojson) ->
      return this.options.show unless geojson?
      this.options.show = geojson
      this._refreshReferenceLayerGroup()

    edit: (geojson) ->
      return this.options.edit unless geojson?
      this.options.edit = geojson
      this._refreshEditionLayerGroup()

    view: (view) ->
      return this.options.view unless view?
      this.options.view = view
      this._refreshView()

    zoom: (zoom) ->
      return this.map.getZoom() unless zoom?
      this.options.view.zoom = zoom
      this._refreshZoom()

    height: (height) ->
      return this.options.box.height() unless height?
      this.options.view.box.height = height
      this._resize()

    _resize: ->
      if this.options.box?
        if this.options.box.height?
          this.mapElement.height this.options.box.height
        if this.options.box.width?
          this.mapElement.width this.options.box.width
        this._trigger "resize"
    
    _refreshBackgroundLayer: ->
      if this.backgroundLayer?
        this.map.removeLayer(this.backgroundLayer)
      if this.options.back?
        if this.options.back.constructor.name is "String"
          this.backgroundLayer = L.tileLayer.provider(this.options.back)
          this.backgroundLayer.addTo this.map
        else
          console.log "How to set background with #{this.options.back}?"
          console.log this.options.back
      this

    _refreshReferenceLayerGroup: ->
      if this.referenceLayerGroup?
        this.referenceLayerGroup.clearLayers()
      if this.options.show?          
        this.referenceLayerGroup = []
        $.each this.options.show, (index, value) ->
          layer = L.GeoJSON.geometryToLayer(value).setStyle
            weight: 1
            color: "#333"
          this.referenceLayerGroup.push layer
          layer.addTo this.map
      this

    _refreshEditionLayerGroup: ->
      if this.editionLayerGroup?
        this.editionLayerGroup.clearLayers()
      if this.options.edit?          
        this.editionLayerGroup = []
        $.each this.options.edit, (index, value) ->
          layer = L.GeoJSON.geometryToLayer(value).setStyle
            weight: 2
            color: "#33A"
          this.editionLayerGroup.push layer
          layer.addTo this.map
      this._refreshControls
      this

    _refreshView: ->
      if this.options.view?
        if this.options.view is 'auto'
          if this.referenceLayerGroup?
            this.map.fitBounds(this.map.referenceLayerGroup.getBounds())
          else if this.editionLayerGroup?
            this.map.fitBounds(this.map.editionLayerGroup.getBounds())
          else
            this.map.fitWorld()
            this.map.setZoom 6
        else if this.options.view.center?
          center = L.latLng(this.options.view.center[0], this.options.view.center[1])
          if this.options.view.zoom?
            this.map.setView(center, this.options.view.zoom)
          else
            this.map.setView(center, 12)
        else if this.options.view.bounds?
          this.map.fitBounds(this.options.view.bounds)
        else
          console.log "How to set view with #{this.options.view}?"
          console.log this.options.view
          
    _refreshZoom: ->
      if this.options.view.zoom?
        this.map.setZoom(this.options.view.zoom)

    _refreshControls: ->
      if this.controls?
        $.each this.controls, (index, value) ->
          this.map.removeControl(value)
      this.controls = []
      unless this.options.controls.zoom is false
        this.controls.push this.map.addControl new L.Control.Zoom
          position: "topleft"
          zoomInText: ""
          zoomOutText: ""
      unless this.options.controls.fullscreen is false
        this.controls.push this.map.addControl new L.Control.FullScreen()
      if this.editionLayerGroup?
        this.controls.push this.map.addControl new L.Control.Draw
          edit:
            featureGroup: this.map.editionLayerGroup
            edit:
              color: "#A40"
          draw:
            marker: false
            polyline: false
            rectangle: false
            circle: false
            polygon:
              allowIntersection: false
              showArea: true
      unless this.options.controls.scale is false
        this.controls.push this.map.addControl new L.Control.Scale(this.options.controls.scale)      
      
  
  # Map editor
  $(document).ready ->
    $("input[data-map-editor]").each ->
      $(this).mapeditor()

    $("input[data-map-editors]").each ->
      input = $(this)
      options = input.data("map-editor")
      input.attr "type", "hidden"
      mapElement = $("<div class=\"map\"></div>")
      if options.box?
        if options.box.height?
          mapElement.height options.box.height
        if options.box.width?
          mapElement.width options.box.width
      input.after mapElement
      map = L.map(mapElement[0],
        maxZoom: 25
        zoomControl: false
        attributionControl: false
      )
      input.prop("map", map)
      L.tileLayer.provider("OpenStreetMap.HOT").addTo map
      
      # L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png', {
      #    attribution: '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'
      # }).addTo(map);
      if options.others
        $.each options.others, (index, value) ->
          L.GeoJSON.geometryToLayer(value).setStyle(
            weight: 1
            color: "#333"
          ).addTo map

      if options.edit
        L.GeoJSON.geometryToLayer(options.edit).setStyle(
          weight: 2
          color: "#333"
        ).addTo map
        map.editedLayer = L.GeoJSON.geometryToLayer(options.edit)
        # alert options.view
        # # TODO: Care about about layers
        # unless options.view?
        #   map.fitBounds(map.editedLayer.getBounds())
      else
        map.editedLayer = new L.FeatureGroup()
      map.editedLayer.addTo map
      
      # Set view box
      if options.view?
        if options.view.center?
          map.setView(L.latLng(options.view.center[0], options.view.center[1]), 12)
          map.setZoom(options.view.zoom) if options.view.zoom?
        else
          map.fitBounds(options.view.bounds) if options.view.bounds?
      else
        map.fitWorld()
        map.setZoom 6      
          
      map.on "draw:created", (e) ->
        map.editedLayer.addLayer e.layer
        input.val JSON.stringify(map.editedLayer.toGeoJSON())
        return

      map.on "draw:edited", (e) ->
        input.val JSON.stringify(map.editedLayer.toGeoJSON())
        return

      map.addControl new L.Control.Zoom(
        position: "topleft"
        zoomInText: ""
        zoomOutText: ""
      )
      map.addControl new L.Control.FullScreen()
      map.addControl new L.Control.Draw(
        edit:
          featureGroup: map.editedLayer
          edit:
            color: "#A40"
        draw:
          marker: false
          polyline: false
          rectangle: false
          circle: false
          polygon:
            allowIntersection: false
            showArea: true
      )
      map.addControl new L.Control.Scale(
        imperial: false
        maxWidth: 200
      )

  true
) jQuery
