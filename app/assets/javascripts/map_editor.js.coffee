#= require_self
#= require mapeditor/simple
#= require mapeditor/categories

((M, $) ->
  "use strict"
  ###
  ## Series managment:
  Series allows to display multiple layers of data on a single map, which can be hidden with the selector.
  I/ Serie handlers:
    Specify series to work with in a hash:
      key: the uniq identifier of the serie
      value: the data of a serie, as a geojson
  II/ Layers handlers:
    Specify layers to display data, in an array of hashes:
      name: identifier of the layer
      label: Visible name in the legend and the selector
      serie: the serie identifier as in the handlers
      type: 'simple' or 'categories', see below
      legend: boolean (true), displays the layer name and color in the legend.
      popup: An array of hashes, which define the way popup is shown:
        type: 'label' or 'input'. A label is a static text whereas an input provide a form to edit properties.
        property_label: text displayed before value
        property_value: the name of the feature property to show/edit
      Handler support layer-scoped styling, as supported by Leaflet (stroke, color, etc.)
  III/ Layer types:
     'simple': Display a single layer, identified by a name and a color.
     'categories': Display a layer where geometries have their own set of properties, as color or opacity.
        reference: The key allows to group geometries to a property, to display distinct categories.
  Example: show: {series: {land_parcels_serie: land_parcels, plants_serie: plants},layers: [{name: :land_parcels, label: :land_parcels.tl, serie: :land_parcels_serie, type: :simple }, {name: :plants, label: :plant.tl, serie: :plants_serie, reference: 'variety', stroke: 2, fillOpacity: 0.7, type: :categories, popup: [{type: :label, property_label: 'My name', property_value: :name}]}]}

  ## Others options:
  withoutLabel: boolean (false), bind label to edition layer
  ###
  M.layer = (layer, data, options) ->
    @layerTypes ?= {}
    if type = @layerTypes[layer.type]
      return new type(layer, data, options)
    else
      console.warn "Invalid layer type: #{layer.type}"
      return null

  M.registerLayerType = (name, klass) ->
    @layerTypes ?= {}
    @layerTypes[name] = klass

  # allow to inject jquery objects and interpolate
  L.Map.Modal.prototype.reloadContent = (content) ->
    $(this._getInnerContentContainer()).find('.modal-body').empty()
    $(this._getInnerContentContainer()).find('.modal-body').append($(content))
    this.update()

  $.widget "ui.mapeditor",
    options:
      box:
        height: 400
        width: null
      minZoom: 0
      maxZoom: 25
      customClass: ''
      back: []
      overlays: []
      show:
        layers: {}
        layerDefaults:
          simple:
            color: "#333"
            fillColor: "#333"
            weight: 2
            opacity: 0.8
            fillOpacity: 0.4
            legend: true
          categories:
            color: "#333"
            fillColor: "#333"
            weight: 2
            opacity: 0.8
            fillOpacity: 0.4
            legend: true
      edit: null
      change: null
      view: 'auto'
      useFeatures: false
      withoutLabel: false
      showStyle:
        color: "#333"
        fillOpacity: 0.4
        weight: 2
        opacity: 0.8
      ghostStyle:
        weight: 4
        color: "#FFF"
        fillOpacity: 0
      defaultLabel: 'Unnamed'
      defaultLevelLabel: 'Level'
      allowAttributesPopup: false
      editStyle:
        weight: 2
        color: "#33A"
        fillOpacity: 0.7
      controls:
        draw:
          edit:
            featureGroup: null
            edit:
              color: "#A40"
              popup: false
          draw:
            marker: false
            polyline: false
            rectangle: false
            circle: false
            polygon:
              allowIntersection: false
              showArea: false
            reactiveMeasure: true
        zoom:
          position: "topleft"
          zoomInText: ""
          zoomOutText: ""
          zoomInTitle: I18n.t("#{I18n.rootKey}.leaflet.zoomInTitle")
          zoomOutTitle: I18n.t("#{I18n.rootKey}.leaflet.zoomOutTitle")
        scale:
          position: "bottomright"
          imperial: false
          maxWidth: 200
        fullscreen:
          position: 'topleft'
          title: I18n.t("#{I18n.rootKey}.leaflet.fullscreenTitle")
        reactiveMeasure:
          metric: true
          feet: false
        importers:
          gml: true
          geojson: true
          kml: true
          title: ''
          content: ''
          buttonTitle: I18n.t("#{I18n.rootKey}.leaflet.importerButtonTitle")
          template: '<div class="modal-header"><i class="leaflet-importer-ctrl"></i><span>{title}</span></div>
                     <div class="modal-body">{content}</div>
                     <div class="modal-footer">
                       <button type="submit" class="{OK_CLS}" data-editor-submit=true>{okText}</button>
                       <button class="{CANCEL_CLS}" data-editor-cancel=true>{cancelText}</button>
                      </div>'
          okText: 'Ok'
          cancelText: 'Cancel'
          OK_CLS: 'btn'
          CANCEL_CLS: 'btn'

    colors: ["#00de00", "#6f006f", "#4ade94", "#004ab9", "#de6f4a", "#b9b925", "#00b994", "#25946f", "#de00b9", "#94006f", "#de6f94", "#252594", "#dede94", "#4a2594", "#940000", "#deb9de", "#00b9b9", "#00de94", "#25254a", "#6fde6f", "#4a0094", "#256f4a", "#6f4a25", "#4a4a00", "#b9006f", "#4a6f25", "#6f946f", "#009425", "#6f4ade", "#2525de", "#b9946f", "#b9b994", "#b9de94", "#de256f", "#b900b9", "#4a4a6f", "#4a2525", "#006fde", "#940025", "#250094", "#b900de", "#4ab9b9", "#00004a", "#6f6fde", "#256fde", "#b92594", "#6f944a", "#6f6f25", "#4ab9de", "#de2525", "#2525b9", "#944a94", "#b94a94", "#946f94", "#b94a6f", "#000094", "#4a6f6f", "#006f00", "#946f4a", "#00256f", "#6f4a6f", "#de6fb9", "#6fdeb9", "#de6f00", "#94b94a", "#94b994", "#6f6fb9", "#b925de", "#de2594", "#dede25", "#6f4a94", "#946f6f", "#de25de", "#b92525", "#6fde94", "#254a25", "#4adeb9", "#00deb9", "#b9b9b9", "#6f4a4a", "#256f25", "#25deb9", "#6f25de", "#94b925", "#b9254a", "#4ade25", "#4a006f", "#25006f", "#94de00", "#6fb925", "#259425", "#6f9425", "#944a00", "#25b9b9", "#25de4a", "#00254a", "#94254a", "#4a6f94", "#002500", "#6fdede", "#deb925", "#b9b9de", "#4a4a94", "#004a4a", "#25b994", "#6f6f00", "#b92500", "#b925b9", "#940094", "#2594de", "#4ade4a", "#949400", "#256f6f", "#de00de", "#6fde25", "#4a6fde", "#4a4ab9", "#deb96f", "#6f0025", "#00b925", "#0000b9", "#254a94", "#4a25b9", "#b9004a", "#b9de00", "#6f254a", "#6f2500", "#94b96f", "#25de00", "#b99425", "#b90025", "#0094b9", "#4ab925", "#4ab96f", "#6fde00", "#b9b96f", "#94b9b9", "#de4a6f", "#4a2500", "#de0000", "#4a4a4a", "#259494", "#9400b9", "#b9deb9", "#254a00", "#0000de", "#dede4a", "#94dede", "#94de25", "#4a9494", "#4a94de", "#6fb9b9", "#dede00", "#b9256f", "#de9494", "#009494", "#006f4a", "#94944a", "#4ab900", "#6f6f4a", "#b99494", "#6f004a", "#4a256f", "#00b9de", "#b99400", "#00b96f", "#deb9b9", "#4a6f00", "#000025", "#00006f", "#00de4a", "#b96f94", "#6fb9de", "#946fde", "#deb900", "#004ade", "#254ab9", "#25de6f", "#94deb9", "#b994de", "#004a25", "#94256f", "#250025", "#6f6f6f", "#4a944a", "#4a25de", "#00b94a", "#4a4a25", "#9400de", "#94004a", "#4a94b9", "#94de94", "#6f256f", "#6fb900", "#b9944a", "#de94de", "#944a25", "#6f2594"]


    _create: ->
      this.oldElementType = this.element.attr "type"
      this.element.attr "type", "hidden"

      $.extend(true, this.options, this.element.data("map-editor"))

      this.mapElement = $("<div>", class: "map #{this.options.customClass}")
        .insertAfter(this.element)
      this.map = L.map(this.mapElement[0],
        zoomControl: false
        attributionControl: true
      )

      this.elementSeries = $('<input>').insertAfter(this.mapElement)
      this.elementSeries.attr "type", "hidden"

      widget = this

      this.counter = 1

      @ghostLabelCluster = L.ghostLabelCluster(type: 'number', innerClassName: 'leaflet-ghost-label-collapsed')
      @ghostLabelCluster.addTo @map

      @ghostLayerLabelCluster = L.ghostLabelCluster(type: 'hidden')
      @ghostLayerLabelCluster.addTo @map


      this.map.on "draw:created", (e) =>
        #Attempt to add a geojson feature
        try
          feature = e.layer.toGeoJSON()

          widget.edition.addData feature
        catch
          widget.edition.addLayer e.layer


        this._refreshControls()
        widget.update()

      this.map.on "draw:edited", (e) ->
        widget.update()


      this.map.on "draw:deleted", (e) ->
        layers = e.layers
        layers.eachLayer (layer) =>
          widget.element.trigger 'mapeditor:feature_delete', layer.feature

        widget.update()

      this._resize()
      # console.log "resized"
      this._refreshBackgroundLayer()
      this._refreshGhostLayerGroup()
      # console.log "backgrounded"
      this._refreshReferenceLayerGroup()
      # console.log "shown"
      this._refreshEditionLayerGroup()

      # console.log "edited"
      this._refreshView()
      # console.log "viewed"
      this._refreshControls()
      # console.log "controlled"

      @updateAttributesSeries = (e) =>
        return unless e.which == 1 || e.which == 13
        e.preventDefault()
        featureId = $(e.currentTarget).closest('.leaflet-popup-content').find('*[data-internal-id]').data('internal-id')
        $newFields = $(e.currentTarget).closest('.popup-content').find('.updateAttributesSerieLabelInput')

        layer = this.findLayer(featureId)

        for field in $newFields
          this.updateFeatureProperties(featureId, $(field).attr('name'), $(field).val())

        if layer.feature and layer.feature.geometry and layer.feature.geometry.type == 'MultiPolygon'
          layer.eachLayer (layer) ->
            layer.closePopup()
        else
          layer.closePopup()

        this.popupizeSerie layer.feature, layer




      @updateAttributes = (e) =>
        return unless e.which == 1 || e.which == 13
        e.preventDefault()
        featureId = $(e.currentTarget).closest('.leaflet-popup-content').find('*[data-internal-id]').data('internal-id')
        newName = $(e.currentTarget).closest('.popup-content').find('input[type="text"]').val()

        if this.options.multiLevels?
          level = $(e.currentTarget).closest('.popup-content').find('select').val()
          this.updateFeatureProperties(featureId, 'level', level)

        layer = this.findLayer(featureId)

        already_exist = this.findLayerByName(newName)

        if already_exist isnt undefined
          if already_exist.feature.properties.internal_id != layer.feature.properties.internal_id
            already_exist = true


        if already_exist is true
          # Don't change the name if a different layer use this name
          $(e.currentTarget).closest('.leaflet-popup-content').find('.leaflet-popup-warning').removeClass 'hide'


        else

          this.updateFeatureProperties(featureId, 'name', newName)


          #update label
          layer.updateLabelContent(layer.feature.properties.name)

          layer.setStyle(this.setFeatureStyle(layer.feature))

          layer.closePopup()

          #update popup
          this.popupize layer.feature, layer

          $(this.element).trigger('mapeditor:feature_update', layer.feature)

        false

      $(this.mapElement).on 'keypress', '.updateAttributesLabelInput', @updateAttributes
      $(this.mapElement).on 'click', '.updateAttributesInPopup', @updateAttributes

      $(this.mapElement).on 'click', '.updateAttributesSerieInPopup', @updateAttributesSeries


      widget.element.trigger "mapeditor:loaded"

    updateFeature: (feature_id, attributeName, attributeValue) ->
      this.updateFeatureProperties(feature_id, attributeName, attributeValue)
      layer = this.findLayer(feature_id)

      #update label
      layer.updateLabelContent(layer.feature.properties.name)

      #update style
      layer.setStyle(this.setFeatureStyle(layer.feature))

      #update popup
      this.popupize layer.feature, layer


    updateFeatureProperties: (feature_id, attributeName, attributeValue) ->
      layer = this.findLayer(feature_id)

      if layer
        layer.feature.properties[attributeName] = attributeValue

    setFeatureStyle: (feature) ->
      levelStyle = {}

      if this.options.multiLevels?
        levelStyle = {fillColor: this.colorize(feature.properties.level)}

      $.extend(true, {}, this.options.editStyle, levelStyle)

    findLayer: (feature_id) ->
      containerLayer = undefined
      @map.eachLayer (layer) =>
        if layer.feature and (parseInt(layer.feature.properties.internal_id) == feature_id)
          containerLayer = layer
          return
      containerLayer

    findLayerByName: (feature_name) ->
      containerLayer = undefined
      this.edition.eachLayer (layer) =>
        if (layer.feature.properties.name == feature_name)
          containerLayer = layer
          return

      return containerLayer

    navigateToLayer: (layer) ->
      this.map.panInsideBounds layer.getBounds(), animate: true


    removeLayer: (layer) ->
      this.edition.removeLayer layer


    popupize: (feature, layer) ->
      popup = ""
      popup += "<div class='popup-header'>"
      id = if feature.properties.id? then "#{feature.properties.id}: " else ''
      popup += "<span class='popup-block-content' data-internal-id='#{feature.properties.internal_id}'>#{id}#{feature.properties.name || this.options.defaultLabel}</span>"
      popup += "<span class='leaflet-popup-warning right hide'></span>"
      popup += "</div>"
      popup += "<div class='popup-content'>"
      popup += "<input type='text' class='updateAttributesLabelInput' value='#{feature.properties.name || this.options.defaultLabel}'/>"

      if this.options.multiLevels?
        popup += "<select>"

        for level in [parseInt(@options.multiLevels.maxLevel)..parseInt(@options.multiLevels.minLevel)]
          selected = ""

          if level == parseInt(feature.properties.level)
            selected = "selected"

          #TODO i18n this
          label = if level == 0 then 'RDC' else "#{@options.multiLevels.levelLabel} #{level}"

          popup += "<option value='#{level}' #{selected}>#{label}</option>"

        popup += "</select>"

      popup += "<input class='updateAttributesInPopup' type='button' value='ok'/>"
      popup += "</div>"

      layer.bindPopup popup, keepInView: true, maxWidth: 600, className: 'leaflet-popup-pane'

    popupizeSerie: (feature, layer) ->
      popup = ""
      popup += "<div class='popup-header'>"
      popup += "<span class='popup-block-content' data-internal-id='#{feature.properties.internal_id}'>#{feature.properties.name || ''}</span>"
      popup += "<span class='leaflet-popup-warning right hide'></span>"
      popup += "</div>"
      popup += "<div class='popup-content'>"
      for attribute in feature.properties['popupAttributes']
        popup += "<div>"
        popup += "<label for='#{attribute.property_value}'>#{attribute.property_label} : </label>"
        switch attribute.type
         when 'input'
          popup += "<input type='text' name='#{attribute.property_value}' class='updateAttributesSerieLabelInput' value='#{feature.properties[attribute.property_value] || ""}'/>"
         else
            # include label
            popup += "<span>#{feature.properties[attribute.property_value] || ''}</span>"
        popup += "</div>"

      popup += "<input class='updateAttributesSerieInPopup' type='button' value='ok'/>"
      popup += "</div>"

      if layer.feature and layer.feature.geometry and layer.feature.geometry.type == 'MultiPolygon'
        layer.eachLayer (layer) ->
          layer.bindPopup popup, keepInView: true, maxWidth: 600, className: 'leaflet-popup-pane'
      else
        layer.bindPopup popup, keepInView: true, maxWidth: 600, className: 'leaflet-popup-pane'

    colorize: (level) ->
      #levels rane is set to [-3,3]
      minLevel = -3
      start = this.colors.indexOf(this.options.multiLevels.startColor)
      stop = this.colors.indexOf(this.options.multiLevels.stopColor)
      colorsRange = this.colors.slice(start, stop)
      colorsRange[Math.abs(minLevel - parseInt(level))]

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

    edit: (geojson, zoom = false) ->
      return this.options.edit unless geojson?
      this.options.edit = geojson
      this._saveUpdates()
      this._refreshEditionLayerGroup()
      if zoom
        this._refreshView('edit')

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
        if this.options.back.constructor.name is "Array"

          if @options.back.length > 0
            baseLayers = {}
            for layer, index in @options.back
              opts = {}
              opts['attribution'] = layer.attribution if layer.attribution?
              opts['minZoom'] = layer.minZoom || @options.minZoom
              opts['maxZoom'] = layer.maxZoom || @options.maxZoom
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
            @map.fitWorld( { maxZoom: @options.maxZoom } )

          overlayLayers = {}

          if @options.overlays.length > 0
            for layer, index in @options.overlays
              opts = {}
              opts['attribution'] = layer.attribution if layer.attribution?
              opts['minZoom'] = layer.minZoom || @options.minZoom
              opts['maxZoom'] = layer.maxZoom || @options.maxZoom
              opts['subdomains'] = layer.subdomains if layer.subdomains?
              opts['opacity'] = (layer.opacity / 100).toFixed(1) if layer.opacity? and !isNaN(layer.opacity)
              opts['tms'] = true if layer.tms
              console.log opts

              overlayLayers[layer.name] =  L.tileLayer(layer.url, opts)


          @layerSelector = new L.Control.Layers(baseLayers, overlayLayers)
          @map.addControl  @layerSelector
        else
          console.log "How to set background with #{this.options.back}?"
          console.log this.options.back
      this

    # Retuns data from a serie found with the given name
    _getSerieData: (name) ->
      if @options.show.series[name]?
        return @options.show.series[name]
      else
        console.error "Cannot find serie #{name}"

    _refreshReferenceLayerGroup: ->
      if this.reference?
        this.map.removeLayer this.reference
      if this.options.show? and this.options.show.layers.length > 0
        if this.options.useFeatures

          if @options.show.series?

            @seriesReferencesLayers = {}

            for layer in @options.show.layers

              data = this._getSerieData(layer.serie)
              options = $.extend true, {}, @options.show.layerDefaults[layer.type], layer, parent: this
              renderedLayer = M.layer(layer, data, options)
              if renderedLayer and renderedLayer.valid()
                # Build layer group
                layerGroup = renderedLayer.buildLayerGroup(this, options)
                layerGroup.name = layer.name
                layerGroup.renderedLayer = renderedLayer
                @seriesReferencesLayers[layer.label] = layerGroup
                @map.addLayer(layerGroup)

          else

            this.reference = L.geoJson(this.options.show, {
              onEachFeature: (feature, layer) =>
                feature.properties ||= {}
                #required for cap_land_parcel_clusters as names are set later
                if not feature.properties.name?
                  feature.properties.name = if feature.properties.id? then "#{this.options.defaultEditionFeaturePrefix}#{feature.properties.id}" else this.defaultLabel

            })
        else
          this.reference = L.GeoJSON.geometryToLayer(this.options.show)

        if this.reference?
          this.reference.setStyle this.options.showStyle
          this.reference.addTo this.map
      this

    _refreshGhostLayerGroup: ->
      if this.ghost?
        this.map.removeLayer this.ghost
      if this.options.ghost?
        if this.options.useFeatures
          this.ghost = L.geoJson(this.options.ghost, {
            onEachFeature: (feature, layer) =>

              label = new L.GhostLabel(className: 'leaflet-ghost-label', toBack: true).setContent(feature.properties.name || feature.properties.id).toCentroidOfBounds(layer.getLatLngs())
              @ghostLayerLabelCluster.bind label, layer

          })
        else
          this.ghost = L.GeoJSON.geometryToLayer(this.options.ghost)

        this.ghost.setStyle this.options.ghostStyle
        this.ghost.addTo this.map
      this

    onEachFeature: (feature, layer) ->
      if feature.properties?
        if not feature.properties.internal_id?
          feature.properties['internal_id'] = new Date().getTime()
          feature.properties['removable'] = true

        if not feature.properties.name?
          feature.properties.name = if feature.properties.id? then "#{this.counter}-  #{this.options.defaultEditionFeaturePrefix}#{feature.properties.id}" else "#{this.counter}-  #{this.options.defaultLabel}"

        this.counter += 1
        feature.properties['level'] = 0 if this.options.multiLevels? and not feature.properties.level?

        unless this.options.withoutLabel
          label = new L.GhostLabel(className: 'leaflet-ghost-label').setContent(feature.properties.name || feature.properties.id).toCentroidOfBounds(layer.getLatLngs())
          @ghostLabelCluster.bind label, layer


      $(this.element).trigger('mapeditor:feature_add', feature)

      if feature.properties? and !!this.options.allowAttributesPopup
        this.popupize(feature, layer)

    featureStyling: (feature) ->
      levelStyle = {}

      if this.options.multiLevels?
        levelStyle = {fillColor: this.colorize(feature.properties.level)}

      $.extend(true, {}, this.options.editStyle, levelStyle)

    _refreshEditionLayerGroup: ->
      if this.edition?
        #remove overlay
        @layerSelector.removeLayer this.edition
        this.map.removeLayer this.edition
      if this.options.edit?
        if this.options.useFeatures

          polys = []
          this.edition = L.geoJson(this.options.edit, {
            onEachFeature: (feature, layer) =>
              #nested function cause geojson doesn't seem to pass binding context
              @onEachFeature(feature, layer)

            style: (feature) =>
              @featureStyling feature
            filter: (feature) =>
              if feature.type == 'MultiPolygon'
                for coordinates in feature.coordinates
                  polys.push {type: 'Polygon', coordinates: coordinates}
              !(feature.type == 'MultiPolygon')
          })
          this.edition.addData(polys)
        else
          this.edition = L.GeoJSON.geometryToLayer(this.options.edit)
      else
        this.edition = L.geoJson(this.options.edit, {
          onEachFeature: (feature, layer) =>
            #nested function cause geojson doesn't seem to pass binding context
            @onEachFeature(feature, layer)

          style: (feature) =>
            @featureStyling feature
        })

#      this.edition.setStyle this.options.editStyle
      this.edition.addTo this.map
      this._refreshControls()
      this._saveUpdates()
      this

    buildMultiLevelLegend: (layers) ->
      html = ""
      levels = []
      layers.eachLayer (layer) =>
        level =  parseInt(layer.feature.properties.level)
        levels.push level if level not in levels

      levels.sort((a,b) -> b-a)

      for level in levels
        html += "<div class='leaflet-legend-item'>"
        html += "<div class='leaflet-legend-body leaflet-multilevel-legend' data-level='#{level}'>"

        color = this.colorize(level)

        label = if level == 0 then 'RDC' else "#{this.options.defaultLevelLabel} #{level}"

        html += "<i class='active' style='background-color: #{color}' title='#{label}'></i>"
        html += "<span>#{label}</span>"
        html += "</div>"
        html += "</div>"

      return html

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
        try
          this.map.fitBounds this.reference.getLayers()[0].getBounds()
        catch
          try
            this.map.fitBounds this.ghost.getLayers()[0].getBounds()
          catch
            this._setDefaultView()
      else if view is 'edit'
         try
          this.map.fitBounds this.edition.getLayers()[0].getBounds()
         catch
           this._setDefaultView()
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
      else
        console.log "How to set view with #{view}?"
      this

    _setDefaultView: ->
      this.map.fitWorld()
      this.map.setZoom 6

    _refreshZoom: ->
      if this.options.view.zoom?
        this.map.setZoom(this.options.view.zoom)

    _refreshControls: ->
      if this.controls?
        for name, control of this.controls
          this.map.removeControl(control)
      this.controls = {}
      unless this.options.controls.zoom is false
        this.controls.zoom = new L.Control.Zoom(this.options.controls.zoom)
        this.map.addControl this.controls.zoom
      unless this.options.controls.fullscreen is false
        this.controls.fullscreen = new L.Control.FullScreen(this.options.controls.fullscreen)
        this.map.addControl this.controls.fullscreen
      if this.edition?
        unless this.options.controls.reactiveMeasure is false
          this.controls.reactiveMeasureControl = new L.ReactiveMeasureControl(this.edition, this.options.controls.reactiveMeasure)
        this.controls.draw = new L.Control.Draw($.extend(true, {}, this.options.controls.draw, {edit: {featureGroup: this.edition}}))
        this.map.addControl this.controls.draw
      unless this.options.controls.scale is false
        this.controls.scale = new L.Control.Scale(this.options.controls.scale)
        this.map.addControl this.controls.scale
      unless this.options.controls.importers.gml is false and this.options.controls.importers.geojson is false and this.options.controls.importers.kml is false

        this.controls.importers_ctrl = new L.Control.EasyButton "<i class='leaflet-importer-ctrl' title='#{this.options.controls.importers.buttonTitle}'></i>", (btn, map) =>
          args =
            title: this.options.controls.importers.title
            onShow: (evt) =>
              modal = evt.modal

              modal.reloadContent(this.options.controls.importers.content)

              $('*[data-editor-submit]', modal._container).on 'click', (e) ->
                $(modal._container).find('form[data-importer-form]').submit()
                e.preventDefault
                return false

              $('*[data-editor-cancel]', modal._container).on 'click', (e) =>
                e.preventDefault
                modal.hide()
                return false

              $('form[data-importer-form]', modal._container).submit ->
                $(this).find('[data-importer-spinner]').addClass('active')

              $(modal._container).on 'ajax:complete','form[data-importer-form]', (e,data) =>

                feature = $.parseJSON(data.responseText)
                $(e.currentTarget).find('[data-importer-spinner]').removeClass('active')

                if feature.alert?
                  $(modal._container).find('#alert').text(feature.alert)
                else
                  this.edition.addData feature
                  this.update()
                  modal.hide()


                this.navigateToLayer this.edition

            onHide: (evt) ->
              modal = evt.modal
              $('*[data-editor-submit], *[data-editor-cancel]', modal._container).off 'click'


          map.fire 'modal', $.extend(true, {}, this.options.controls.importers, args )

        this.controls.importers_ctrl.button['type'] = 'button'

        this.map.addControl this.controls.importers_ctrl
        this.map.addControl this.controls.reactiveMeasureControl



      this.controls.legend = new L.control(position: "bottomright")
      this.controls.legend.onAdd = (map) =>
        L.DomUtil.create('div', 'leaflet-legend-control')

      this.map.addControl this.controls.legend


      if this.options.multiLevels?
        legend = @controls.legend.getContainer()

        legend.innerHTML += this.buildMultiLevelLegend(this.edition)

        $(legend).on 'click', '.leaflet-multilevel-legend', (e) =>
          e.preventDefault()
          level = $(e.currentTarget).data('level')
          if level?
            this.edition.eachLayer (layer) =>
              if parseInt(layer.feature.properties.level) == level
                shape = $(layer._container)
                shape.toggle()
                $(e.currentTarget).children('i').toggleClass('active')

      if @options.overlaySelector?

        @map.on "overlayadd", (event) =>

          @layersScheduler.schedule event.layer

          # for each layer in the layerGroup
          event.layer.eachLayer (layer) =>
            @ghostLabelCluster.bind layer.label, layer unless layer.label is undefined
          @ghostLabelCluster.refresh()


        @map.on "overlayremove", (event) =>

          event.layer.eachLayer (layer) =>
            @ghostLabelCluster.removeLayer target: { label: layer.label } unless layer.label is undefined
          @ghostLabelCluster.refresh()

        @layersScheduler = L.layersScheduler()
        @layersScheduler.addTo @map
        selector = @layerSelector || new L.Control.Layers()

        if @ghost? and @ghost.getLayers().length
          selector.addOverlay(@ghost, @options.overlaySelector.ghostLayer)
          @layersScheduler.insert @ghost._leaflet_id, back: true

        if @reference? and @reference.getLayers().length > 0
          selector.addOverlay(@reference, @options.overlaySelector.referenceLayer)
          @layersScheduler.insert @reference._leaflet_id


        if @seriesReferencesLayers?
          for label, layer of @seriesReferencesLayers
            selector.addOverlay(layer, label)
            @layersScheduler.insert layer._leaflet_id
            @controls.legend.getContainer().innerHTML += layer.renderedLayer.buildLegend() if layer.renderedLayer.options.legend


        if @edition? and @edition.getLayers().length > 0
          selector.addOverlay(@edition, @options.overlaySelector.editionLayer)
          @layersScheduler.insert @edition._leaflet_id


    _saveUpdates: ->
      if this.edition?
        this.element.val JSON.stringify(this.edition.toGeoJSON())
      true

    _saveUpdatesSeries: ->
      if this.seriesReferencesLayers?
        geojson = []
        for layerGroup in @seriesReferencesLayers
          geojson.push layerGroup.serie.toGeoJSON()

        this.elementSeries.val JSON.stringify(geojson)
      true

    update: ->
      this._saveUpdates()
      this._saveUpdatesSeries()
      this._refreshControls()
      this.element.trigger "mapchange"

  $(document).ready ->
    $("input[data-map-editor]").each ->
      $(this).mapeditor()

  $(document).on 'dialog:show', ->
    $("input[data-map-editor]").each ->
      $(this).mapeditor()

) mapeditor, jQuery
