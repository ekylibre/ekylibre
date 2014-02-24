(($) ->
  "use strict"
  $.fn.mapsFromData = ->
    $(this).each ->
      mapElement = $(this)
      options = {}
      map = {}
      wkt = new Wkt.Wkt()
      if mapElement.prop("mapLoaded") isnt true
        options = mapElement.data("map")
        
        # Box
        if options.box
          mapElement.height options.box.height  if options.box.height
          mapElement.width options.box.width  if options.box.width
        mapElement.css display: "block"
        map = L.map(mapElement[0],
          maxZoom: 25
          scrollWheelZoom: false
          zoomControl: false
          attributionControl: false
        )
        map.addControl L.control.zoom(
          position: "topleft"
          zoomInText: ""
          zoomOutText: ""
        )
        
        # Add an OpenStreetMap tile layer
        L.tileLayer.provider("OpenStreetMap.HOT").addTo map
        $.each options.geometries, (index, value) ->
          layer = undefined
          if value.shape
            layer = L.GeoJSON.geometryToLayer(value.shape).setStyle(weight: 2)
            if value.url
              layer.on "click", (e) ->
                window.location.assign value.url
                return

            layer.addTo map
          return

        
        # Scale
        map.addControl new L.Control.Scale(
          imperial: false
          maxWidth: 200
        )
        
        # Bounding box
        map.fitBounds L.latLngBounds(options.view.boundingBox)  if options.view and options.view.boundingBox
        mapElement.prop "mapLoaded", true
      return

    return

  $.loadMaps = ->
    $("*[data-map]").mapsFromData()
    return

  $(document).ready $.loadMaps
  $(document).on "page:load cocoon:after-insert cell:load", $.loadMaps

  # Map editor
  $(document).ready ->
    $("input[data-map-editor]").each ->
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
        editedLayer = L.GeoJSON.geometryToLayer(options.edit)
        # alert options.view
        # # TODO: Care about about layers
        # unless options.view?
        #   map.fitBounds(editedLayer.getBounds())
      else
        editedLayer = new L.FeatureGroup()
        unless options.view?
          map.fitWorld()
          map.setZoom 6
      editedLayer.addTo map
      
      # Set view box
      if options.view?
        if options.view.center?
          map.setView(L.latLng(options.view.center[0], options.view.center[1]), 12)
          map.setZoom(options.view.zoom) if options.view.zoom?
        else
          map.fitBounds(options.view.bounds) if options.view.bounds?
      map.on "draw:created", (e) ->
        editedLayer.addLayer e.layer
        input.val JSON.stringify(editedLayer.toGeoJSON())
        return

      map.on "draw:edited", (e) ->
        input.val JSON.stringify(editedLayer.toGeoJSON())
        return

      map.addControl new L.Control.Zoom(
        position: "topleft"
        zoomInText: ""
        zoomOutText: ""
      )
      map.addControl new L.Control.FullScreen()
      map.addControl new L.Control.Draw(
        edit:
          featureGroup: editedLayer
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
      return

    return

  return
) jQuery
