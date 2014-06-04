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
      if this.options.layers
        $.each this.options.layers, ( index, value ) ->
          max_value = 0
          min_value = 0
          if value.list[1]['style'] = 'choropleth'
            max_value = value.list[1]['choropleth_value']
            min_value = value.list[1]['choropleth_value']
          choro = false 
          level_number = 0 
          start = ""
          end = ""
          $.each value.list, (index, value) ->
            if value.style == 'choropleth'              
              level_number = value.choropleth_level_number
              choro = true
              start = value.choropleth_start_color
              end = value.choropleth_end_color
              if value.choropleth_value > max_value
                max_value = value.choropleth_value
              if value.choropleth_value < min_value
                min_value = value.choropleth_value
          if choro == true       
            start_red = parseInt(start.slice(1,3),16)
            start_green = parseInt(start.slice(3,5),16)
            start_blue = parseInt(start.slice(5,7),16)
            end_red = parseInt(end.slice(1,3),16)
            end_green = parseInt(end.slice(3,5),16)
            end_blue = parseInt(end.slice(5,7),16)
            red_gap = Math.ceil((start_red - end_red)/level_number)
            green_gap = Math.ceil((start_green - end_green)/level_number)
            blue_gap = Math.ceil((start_blue - end_blue)/level_number)
            
          $.each value.list, (index, value) ->
            if value.style == 'choropleth'
              value.max_value = max_value
              value.min_value = min_value  
              color_level = Math.ceil(value.choropleth_value/((max_value-min_value)/level_number))
              value.level = color_level               
              red_int = start_red - (red_gap*color_level)       
              red_string = (red_int).toString(16)
              if red_int <= 0
                fillColor_red = "00"
              else if red_int < 16
                fillColor_red ="0" + red_string
              else if red_int > 255
                fillColor_red ="FF"
              else
                fillColor_red = red_string
                
              green_int = start_green - (green_gap*color_level)       
              green_string = (green_int).toString(16)
              if green_int <= 0
                fillColor_green = "00"
              else if green_int < 16
                fillColor_green = "0" + green_string
              else if green_int > 255
                fillColor_green = "FF"
              else
                fillColor_green = green_string
                
              blue_int = start_blue - (blue_gap*color_level)       
              blue_string = (blue_int).toString(16)
              if blue_int <= 0
                fillColor_blue = "00"
              else if blue_int < 16
                fillColor_blue ="0" + blue_string
              else if blue_int > 255
                fillColor_blue ="FF"
              else
                fillColor_blue = blue_string        
              value.fillColor = "#" + fillColor_red + fillColor_green + fillColor_blue
      this
      #sky_blue = this.options.COLORS[0]
      #midnight_blue = this.options.COLORS[1]
      #swamp_green = this.options.COLORS[2]
      #bordeaux_red = this.options.COLORS[3]
      #turquoise_blue = this.options.COLORS[4]
      #dark_purple = this.options.COLORS[5]
      #ochre_orange = this.options.COLORS[6]
      #pastel_blue = this.options.COLORS[7]
      #brick_red = this.options.COLORS[8]
      #pale_green = this.options.COLORS[9]
      #if this.options.layers
        #$.each this.options.layers, ( index, value ) ->
          #max_value = 0
          #choro = false
          #$.each value.list, (index, value) ->
            #if value.style == 'choropleth'
              #choro = true
              #if value.choropleth_value > max_value
                #max_value = value.choropleth_value
          #if choro == true
            #$.each value.list, (index, value) ->
              #if value.style == 'choropleth'
                #level_size = 255/value.choropleth_level_number
                #choro_level = (Math.ceil(((value.choropleth_value/(max_value/value.choropleth_level_number))*10)/10))*level_size

                #switch value.choropleth_color
                  #when "red" then value.fillColor = red[choro_level] 
                  #when "sky_blue" then value.fillColor = lighten(sky_blue, choro_level)
                  #when "green" then value.fillColor = green[choro_level]
                  #when "purple" then value.fillColor = purple[choro_level]
                  #when "cian" then value.fillColor = cian[choro_level]
                  #when "yellow" then value.fillColor = yellow[choro_level]
                  #else alert "This color isn't available"


                
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
              
              legend = new L.control(position: "bottomright")
              bubble_legend = false
              choropleth_legend = false
              simple_legend = false
              legend_name = value.name
              div = new L.DomUtil.create("div", "leaflet-legend-control")
              color ='#000000'
              bubble_grades = 4
              max_bubble_value = null
              max_bubble_value_digits = null
              choropleth_grades = {}
              choropleth_max_value = null
              choropleth_min_value = null
              choropleth_level_value = {}
              simple_grades = {}
              
              $.each value.list, (index, value) ->
                                                
                if value.style == 'simple'
                  
                  simple_legend = true
                  simple_grades[value.category] = value.fillColor
                  
                  simple_layer = new L.GeoJSON(value.coord, {stroke: value.stroke, color: value.color, weight: value.weight, opacity: value.opacity, fill: value.fill, fillColor: value.fillColor, fillOpacity: value.fillOpacity} )
                  tmp = value.area.value.split("/")
                  popup = "#{value.name} <br> Area :  #{Math.round(tmp[0]/tmp[1])} #{value.area.unit} <br> Category : #{value.category_name}"
                  simple_layer.bindPopup(popup)
                  layer_group.push(simple_layer)
                  
                else if value.style == 'bubble'
                  
                  bubble_legend = true
                  if value.radius > max_bubble_value
                    color = value.fillColor
                    max_bubble_value = value.radius
                    max_bubble_value_digits = (max_bubble_value.toString().length)-1
                    
                  bubble_layer = new L.Circle(value.center, value.radius, {stroke: value.stroke, color: value.color, weight: value.weight, opacity: value.opacity, fill: value.fill, fillColor: value.fillColor, fillOpacity: value.fillOpacity} )
                  popup = "#{value.name} <br> Amount of potassium :  #{Math.round(value.radius)} grames by square meter"
                  bubble_layer.bindPopup(popup)
                  layer_group.push(bubble_layer)   
                                     
                               
                else if value.style == 'choropleth'  
                  
                  choropleth_legend = true
                  choropleth_max_value = value.max_value
                  choropleth_min_value = value.min_value
                  choropleth_grades[value.level] = value.fillColor
                  choropleth_level_value[value.level] = Math.round((value.max_value/value.choropleth_level_number)*value.level)
                  
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
              
              legend.onAdd = (map) ->
                                
                if bubble_legend == true
                  
                  div.innerHTML += legend_name
                  div.innerHTML += "<br>"
                  i = 0
                  while i <= bubble_grades
                    rounded_max_value = Math.ceil(max_bubble_value/Math.pow(10,max_bubble_value_digits))*Math.pow(10,max_bubble_value_digits) 
                    rounded_max_value *= (i/bubble_grades)
                    width = rounded_max_value /3
                    height = rounded_max_value /3
                    div.innerHTML += '<i class="leaflet-legend-circle" style="background-color:' + color + "; width: #{width}px; height: #{height}px" + '"></i>'  + " " + rounded_max_value +  " "
                    i++
                if choropleth_legend == true
                   
                  div.innerHTML += legend_name
                  div.innerHTML += "<br>" + "<br>"
                  div.innerHTML += choropleth_min_value
                  $.each choropleth_grades, ( index, value ) ->               
                    div.innerHTML += '<i class="leaflet-legend-control" style="background:' + value + '"></i>'      
                  div.innerHTML += choropleth_max_value
                  div.innerHTML += "<br>" + "<br>"
               
                if simple_legend == true
                  
                  div.innerHTML += legend_name
                  div.innerHTML += "<br>"   
                  $.each simple_grades, ( index, value ) ->
                    div.innerHTML += '<i class="leaflet-legend-circle" style="background:' + value + '"></i>' + " " + index +  " "
                    div.innerHTML += "<br>"
                                 
                div
              legend.addTo that.map

            layer_options = {
              collapsed: true,
              position: 'topright',
              autoZIndex: true
            }
            controls = new L.Control.Layers(baseLayers, overlays,layer_options)
            #that.map.removeControl (controls)
            that.map.addControl controls
                
          # if value.name == 'layer_legend' 
            # legend = new L.control(position: "bottomright")
            # legend.onAdd = (map) ->
              # div = new L.DomUtil.create("div", "leaflet-legend-control")
              # color ='#000000'
              # bubble_grades = 4
              # max_bubble_value = 0
              # max_bubble_value_digits = 0
              # choropleth_grades = {}
              # simple_grades = {}
              # $.each layers, ( index, value ) ->  
                # $.each value.list, (index, value) ->
                  # if value.style == 'bubble'
                    # if value.radius > max_bubble_value
                      # color = value.fillColor
                      # max_bubble_value = value.radius
                      # max_bubble_value_digits = (max_bubble_value.toString().length)-1                   
# 
                  # if value.style == 'simple'
                    # simple_grades[value.category] = value.fillColor
# 
                  # if value.style == 'choropleth'
                    # choropleth_grades[value.level] = value.fillColor
# 
              # i = 0
              # while i <= bubble_grades
                # rounded_max_value = Math.ceil(max_bubble_value/Math.pow(10,max_bubble_value_digits))*Math.pow(10,max_bubble_value_digits)
                # width = rounded_max_value 
                # height = rounded_max_value 
                # div.innerHTML += '<i class="leaflet-legend-circle" style="background:' + color +  '"></i>'  + " " + rounded_max_value*(i/bubble_grades) +  " "
                # i++
              # div.innerHTML += "<br>" + "<br>" 
#               
              # $.each choropleth_grades, ( index, value ) ->
                # div.innerHTML += '<i class="leaflet-legend-control" style="background:' + value +  '"></i>'  
              # div.innerHTML += "<br>" + "<br>"     
#               
              # $.each simple_grades, ( index, value ) ->
                # div.innerHTML += '<i class="leaflet-legend-circle" style="background:' + value +  '"></i>' + " " + index +  " "
                # div.innerHTML +=  "<br>"
#                                  
              # div
            # legend.addTo that.map                    
            
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


