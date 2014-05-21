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
      layers: {}
      show: null
      edit: null
      change: null
      view: 
        center:[]
        zoom : 13
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
       
      this.mapElement = $("<div>", class: "map")
        .insertAfter(this.element)
      this.map = L.map(this.mapElement[0],
        maxZoom: 18
        minZoom:2
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
      
      #this._refreshBubbles()
      
      #this._refreshPolygons()
      
      this._calculChoropleth()

      this._refreshControls()
           
      #this._refreshPolygons()
      

      

     
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
 
    _resize: -> 
      if this.options.box?
        if this.options.box.height?
          this.mapElement.height this.options.box.height
        if this.options.box.width?
          this.mapElement.width this.options.box.width
        this._trigger "resize"
        
    _calculChoropleth: ->
      if this.options.layers
        $.each this.options.layers, ( index, value ) ->
          max_value = 0
          choro = false  
          $.each value.list, (index, value) ->
            if value.style == 'choropleth'
              choro = true
              if value.choropleth_value == 'area'
                tmp = value.area.value.split("/")
                value.choropleth_value = Math.round(tmp[0]/tmp[1])
              if value.choropleth_value > max_value
                max_value = value.choropleth_value
          if choro == true
            $.each value.list, (index, value) ->
              if value.style == 'choropleth'
                choro_color = Math.round(value.choropleth_value/(max_value/10))
                if choro_color == 0
                  choro_color = 1
                choro_color = Math.round(choro_color*25.5)
                choro_color1 = choro_color
                choro_color = 280 - choro_color
                choro_color = choro_color.toString(16)
                choro_color1 = choro_color1.toString(16)
                console.log choro_color       
                if value.choropleth_color == 'red'
                  value.fillColor = '#FF'+ choro_color + choro_color
                  console.log value.fillColor
                if value.choropleth_color == 'yellow'
                  value.fillColor = '#FFFF' + choro_color
                if value.choropleth_color == 'orange'
                  value.fillColor = '#FF80' + choro_color1 + choro_color
                  console.log value.fillColor
                if value.choropleth_color == 'green'
                  value.fillColor = '#' + choro_color + 'FF'+ choro_color
                  console.log value.fillColor
                if value.choropleth_color == 'cian'
                  value.fillColor = '#' + choro_color + 'FFFF'
                  console.log value.fillColor
                if value.choropleth_color == 'blue'
                  value.fillColor = '#' + choro_color + choro_color + 'FF'
                  console.log value.fillColor
                if value.choropleth_color == 'pink'
                  value.fillColor = '#FF' + choro_color + 'FF'
                  console.log value.fillColor
                
    _refreshControls: ->
      that= this
      layers = this.options.layers
      back = this.options.backgrounds
      over = this.options.overlays

      if this.options.controls? 
        $.each this.options.controls, ( index, value ) ->
          if value.name == "fullscreen" 
            fullscreen_options = {
              position: 'topleft',
            }
            controls = new L.Control.FullScreen(fullscreen_options)
            that.map.addControl controls
          #alert( index + ": " + value )            
          if value.name == "zoom"
           zoom_options = {
             position: 'topleft',
             zoomInText: '',
             zoomInTitle: 'Zoom in',
             zoomOutText: '',
             zoomOutTitle: 'Zoom out'
           }
           controls = new L.Control.Zoom(zoom_options)
           #that.map.removeControl (controls)
           that.map.addControl controls
           
          if value.name == "scale"
            scale_options = {
              position: 'bottomleft',
              maxWidth: 200,
              metric: true,
              imperial: false,
              updateWhenIdle: false
            }
            controls = new L.Control.Scale(scale_options)
            that.map.addControl controls
                       
          if value.name == "layer_selector"
            baseLayers = {}
            overlays = {}
            $.each back, ( index, value ) -> 
              backgroundLayer = L.tileLayer.provider(value.provider_name)
              baseLayers[value.name] = backgroundLayer
              if value.name == "default_base"
                that.map.addLayer(backgroundLayer)
            
            $.each over, ( index, value ) -> 
              overLayer = L.tileLayer.provider(value.provider_name)
              overlays[value.name] = overLayer
              
            $.each layers, ( index, value ) ->  
              layer_group = []           
              $.each value.list, (index, value) ->
                if value.style == 'simple'
                  simple_layer = new L.GeoJSON(value.coord, {stroke: value.stroke, color: value.color, weight: value.weight, opacity: value.opacity, fill: value.fill, fillColor: value.fillColor, fillOpacity: value.fillOpacity} )
                  tmp = value.area.value.split("/")
                  popup = "#{value.name} <br> Area :  #{Math.round(tmp[0]/tmp[1])} #{value.area.unit} <br> Category : #{value.category}"
                  simple_layer.bindPopup(popup)
                  layer_group.push(simple_layer)
                if value.style == 'bubble'
                  bubble_layer = new L.circle(value.coord, value.radius, {stroke: value.stroke, color: value.color, weight: value.weight, opacity: value.opacity, fill: value.fill, fillColor: value.fillColor, fillOpacity: value.fillOpacity} )
                  popup = "#{value.name} <br> Amount of potassium :  #{Math.round(value.radius)} grames by square meter"
                  bubble_layer.bindPopup(popup)
                  layer_group.push(bubble_layer)
                if value.style == 'choropleth'   
                  choropleth_layer = new L.GeoJSON(value.coord, {stroke: value.stroke, color: value.color, weight: value.weight, opacity: value.opacity, fill: value.fill, fillColor: value.fillColor, fillOpacity: value.fillOpacity} )
                  tmp = value.area.value.split("/")
                  popup = "#{value.name} <br> Area :  #{Math.round(tmp[0]/tmp[1])} #{value.area.unit} <br> Category : #{value.category}"
                  choropleth_layer.bindPopup(popup)
                  layer_group.push(choropleth_layer)
              overLayer = L.layerGroup(layer_group)
              overlays[value.name] = overLayer
              that.map.addLayer(overLayer)

            layer_options = {
              collapsed: true,
              position: 'topright',
              autoZIndex: true
            }
            controls = new L.Control.Layers(baseLayers, overlays,layer_options)
            #that.map.removeControl (controls)
            that.map.addControl controls
            
          #if value.name == 'layer_legend'
            #legend = new L.Control({position: 'bottomright'})
            #legend.onAdd (map) ->
              #div = new L.DomUtil.create("div", "info legend")
              #grades = [
                #0
                #10
                #20
                #50
                #100
                #200
                #500
                #1000
              #]

            

            
          if value.name == "geocoder"  
            geocoder_options = {
              collapsed: true,
              position: 'topright',
              text: 'Locate',
              bounds: null, 
              email: null
            }
            controls = new L.Control.OSMGeocoder(geocoder_options)
            that.map.addControl controls
            
      this

 
    _refreshReferenceLayerGroup: ->
      if this.reference?
        this.map.removeLayer this.reference
      if this.options.show?
        this.reference = L.GeoJSON.geometryToLayer(this.options.show).setStyle this.options.showStyle
        this.reference.addTo this.map
      this
 
 
    _refreshView: (view) ->
      east = this.options.layers[1].list[0].coord[0]
      west = this.options.layers[1].list[0].coord[0]
      north = this.options.layers[1].list[0].coord[1]
      south = this.options.layers[1].list[0].coord[1]
      long = null
      lat = null
      coord = []
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
        if this.options.layers?
          $.each this.options.layers, ( index, value ) -> 
            $.each value.list , (index, value) ->
              if value.coord[0] < west
                west = value.coord[0]
              if value.coord[0] > east
                east = value.coord[0]
              if value.coord[1] < south
                south = value.coord[1]
              if value.coord[1] > north
                north = value.coord[1]
        long = (west + east)/2
        lat = (north + south)/2
        coord = [long, lat] 
        center = L.latLng(coord)
        if view.zoom?
          this.map.setView(center, view.zoom)
        else
          this.map.setView(center, zoom)
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


