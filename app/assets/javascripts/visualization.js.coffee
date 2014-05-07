(($) ->
  "use strict"
 
  $.widget "ui.visualization",
    options:
      box:
        height: 400
        width: null
      backgrounds:{}
      overlays: {}
      controls:{}
      show: null
      edit: null
      change: null
      view: 'auto'
      showStyle:
        weight: 1
        color: "#333"
      editStyle:
        weight: 2
        color: "#33A"
      #controls:
        #draw:
          #edit:
            #featureGroup: null
            #edit:
              #color: "#A40"
          #draw:
            #marker: false
            #polyline: false
            #rectangle: false
            #circle: false
            #polygon:
             #allowIntersection: false
              #showArea: true 
           
        #zoom:
          #position: "topleft"
          #zoomInText: ""
          #zoomOutText: ""
        #scale:
          #position: "bottomleft"
          #imperial: false
          #maxWidth: 200
        #tilelegend:
          #position: "bottomright"
          #title: "HOT style"
          #description: "Humanitarian focused OSM base layer."
          #sections: [
            #title: "Roads"
            #className: "roads"
            #keys: [
              #coordinates: [
                #19.67236
                #-72.11825
                #15
              #]
              #text: "Paved primary road"
            #]
          #]
                
    _create: ->     
      $.extend(true, this.options, this.element.data("visualization"))
      console.log "create"
      console.log this.options
       
      this.mapElement = $("<div>", class: "map")
        .insertAfter(this.element)
      this.map = L.map(this.mapElement[0],
        maxZoom: 25
        zoomControl: false
        attributionControl: false 
      )
 
      
      # this.map.on "draw:created", (e) ->
      #   widget.edition.addLayer e.layer
      #   widget._saveUpdates()
      #   widget.element.trigger "mapchange"
          
      # this.map.on "draw:edited", (e) ->
      #   widget._saveUpdates()
      #   widget.element.trigger "mapchange"
 
      # this.map.on "draw:deleted", (e) ->
      #   widget._saveUpdates()
      #   widget.element.trigger "mapchange"
        
      
      #this.show()
      
      #this.edit()
      
      #this.view()
      
      #this.height()
      
      #this.zoom()
      
      #this._saveUpdates()
      
      #this._setDefaultView()

      this._resize()

      this._refreshView()

      this._refreshControls()

     
    _destroy: ->
      this.element.attr this.oldElementType
      this.mapElement.remove()
       
       
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
      return this.options.box.height unless height?
      this.options.view.box.height = height
      this._resize()
      console.log this.options.view.box.height
 
    _resize: ->
      console.log "resize"
      if this.options.box?
        if this.options.box.height?
          this.mapElement.height this.options.box.height
        if this.options.box.width?
          this.mapElement.width this.options.box.width
        this._trigger "resize"
           
    _refreshControls: ->
      that= this
      
      back = this.options.backgrounds
      over = this.options.overlays

      if this.options.controls? 
        $.each this.options.controls, ( index, value ) ->
          if value.name == "fullscreen" 
            #options = {position: "bottomleft", metric: true, imperial: false, maxWidth: 200}
            controls = new L.Control.FullScreen(position: "bottomleft", metric: true, imperial: false, maxWidth: 200)
            that.map.addControl controls
          #alert( index + ": " + value )            
          if value.name == "zoom"
            controls = new L.Control.Zoom()
            #that.map.removeControl (controls)
            that.map.addControl controls
            #alert( index + ": " + description )
          if value.name == "tilelegend"
            controls = new L.Control.TileLegend()
            #that.map.removeControl (controls)
            that.map.addControl controls
            #alert( index + ": " + description )
          if value.name == "scale"
            controls = new L.Control.Scale()
            #that.map.removeControl (controls)
            that.map.addControl controls
            #alert( index + ": " + description )
          if value.name == "layer_selector"
            console.log "Vive le Roi!"
            baseLayers = {}
            overlays = {}
            $.each back, ( index, value ) -> 
              backgroundLayer = L.tileLayer.provider(value.provider_name)
              baseLayers[value.name] = backgroundLayer

            $.each over, ( index, value ) -> 
              overLayer = L.tileLayer.provider(value.provider_name)
              overlays[value.name] = overLayer
            controls = new L.Control.Layers(baseLayers, overlays)

            #that.map.removeControl (controls)
            that.map.addControl controls
            $.each baseLayers, ( index, value ) -> 
              #if value.name == "default_base"
                
            #alert( index + ": " + description )    
          

      this

        #for name, control of this.controls
          #this.map.removeControl(control)
      #this.controls = {}
      #unless this.options.controls.zoom is false
        #this.controls.zoom = new L.Control.Zoom(this.options.controls.zoom)
        #this.map.addControl this.controls.zoom
      #unless this.options.controls.fullscreen is false
        #this.controls.fullscreen = new L.Control.FullScreen(this.options.controls.fullscreen)
        #this.map.addControl this.controls.fullscreen
        # if this.edition?
        #   this.controls.draw = new L.Control.Draw($.extend(true, {}, this.options.controls.draw, {edit: {featureGroup: this.edition}}))
        #   this.map.addControl this.controls.draw
      #unless this.options.controls.scale is false
        #this.controls.scale = new L.Control.Scale(this.options.controls.scale)
        #this.map.addControl this.controls.scale
      #unless this.options.controls.tilegend is false
        #this.controls.tilelegend = new L.Control.TileLegend(this.options.controls.tilelegend)
        #this.map.addControl this.controls.tilelegend
 
 
    _refreshReferenceLayerGroup: ->
      if this.reference?
        this.map.removeLayer this.reference
      if this.options.show?
        this.reference = L.GeoJSON.geometryToLayer(this.options.show).setStyle this.options.showStyle
        this.reference.addTo this.map
      this
 
 
    _refreshView: (view) ->
      view ?= this.options.view
      if view is 'auto'
        try
          this._refreshView('show')
        catch
          try
            this._refreshView('edit')
          catch
            this._setDefaultView()
      else if view is 'show'
        this.map.fitBounds this.reference.getLayers()[0].getBounds()
      else if view is 'edit'
        this.map.fitBounds this.edition.getLayers()[0].getBounds()
      else if view is 'default'
        this._setDefaultView()
      else if view.center?
        center = L.latLng(view.center[0], view.center[1])
        if view.zoom?
          this.map.setView(center, view.zoom)
        else
          this.map.setView(center, 12)
      else if view.bounds?
        this.map.fitBounds(view.bounds)
      this
 
    _setDefaultView: ->
      this.map.fitWorld()
      this.map.setZoom 6
           
    _refreshZoom: ->
      if this.options.view.zoom?
        this.map.setZoom(this.options.view.zoom)

    _saveUpdates: ->
      if this.edition?
        this.element.val JSON.stringify(this.edition.toGeoJSON())
      true
 
  $(document).ready ->
    $("*[data-visualization]").each ->
      $(this).visualization()
       
) jQuery


