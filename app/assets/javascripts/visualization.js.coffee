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
      blue_choropleth_palette: ['#ffffff', '#9999ff', '#6666ff', '#3232ff', '#0000ff', '#0000cc', '#000099', '#000066']
      red_choropleth_palette: ['#ffffff', '#ff9999', '#ff6666', '#ff3232', '#ff0000', '#cc0000', '#990000', '#660000']
      green_choropleth_palette: ['#ffffff', '#99ff99', '#66ff66', '#32ff32', '#00ff00', '#00cc00', '#009900', '#006600']
      purple_choropleth_palette: ['#ffffff', '#cc99cc', '#b266b2', '#993299', '#800080', '#660066', '#4c004c', '#330033']
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
      this._calculArea()
      
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
        
    _calculArea: ->
      if this.options.layers
        $.each this.options.layers, ( index, value ) ->
          $.each value.list, (index, value) ->
            if value.choropleth_value == 'area'
              tmp = value.area.value.split("/")
              value.choropleth_value = Math.round(tmp[0]/tmp[1])
        
    _calculChoropleth: ->
      red = this.options.red_choropleth_palette
      blue = this.options.blue_choropleth_palette
      green = this.options.green_choropleth_palette
      purple = this.options.purple_choropleth_palette      
      if this.options.layers
        $.each this.options.layers, ( index, value ) ->
          max_value = 0
          choro = false  
          $.each value.list, (index, value) ->
            if value.style == 'choropleth'
              choro = true
              if value.choropleth_value > max_value
                max_value = value.choropleth_value
          if choro == true
            $.each value.list, (index, value) ->
              if value.style == 'choropleth'
                choro_color = Math.ceil(((value.choropleth_value/(max_value/7))*10)/10)
                switch value.choropleth_color
                  when "red" then value.fillColor = red[choro_color]
                  when "blue" then value.fillColor = blue[choro_color]
                  when "green" then value.fillColor = green[choro_color]
                  when "purple" then value.fillColor = purple[choro_color]
                  else alert "This color isn't available"
      this

                
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
                  bubble_layer = new L.circle(value.center, value.radius, {stroke: value.stroke, color: value.color, weight: value.weight, opacity: value.opacity, fill: value.fill, fillColor: value.fillColor, fillOpacity: value.fillOpacity} )
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
              group = new L.featureGroup(layer_group)
              that.map.addLayer(overLayer)
              that.map.fitBounds(group.getBounds())

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
      this._setDefaultView()
      #else if view.center?
        #if this.options.layers?

        #if view.zoom?
          #this.map.setView(center, view.zoom)
        #else
          #this.map.setView(center, zoom)
      #this
 
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


