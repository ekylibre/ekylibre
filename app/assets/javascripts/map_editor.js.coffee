(($) ->
  "use strict"

  # allow to inject jquery objects and interpolate
  L.Map.Modal.prototype.reloadContent = (content, options) ->
    inject = L.Util.template(
      content,
      options
    )
    $(this._getInnerContentContainer()).find('.modal-body').empty()
#    $(this._getInnerContentContainer()).find('.modal-body > :first-child').replaceWith($content)
    $(this._getInnerContentContainer()).find('.modal-body').append($(inject))
    this.update()

  L.Control.EasyBar.addCustomClasses = (el, classes) ->
    L.DomUtil.addClass(el.container,classes)

  $.widget "ui.mapeditor",
    options:
      box:
        height: 400
        width: null
      back: "Esri.WorldImagery"
      show: null
      edit: null
      change: null
      view: 'auto'
      useFeatures: false
      showStyle:
        weight: 1
        color: "#333"
        fillOpacity: 0.2
      defaultLabel: 'Sans nom'
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
              showArea: true
        zoom:
          position: "topleft"
          zoomInText: ""
          zoomOutText: ""
        scale:
          position: "bottomright"
          imperial: false
          maxWidth: 200
        measure:
          show :false
          position: 'bottomleft'
          primaryLengthUnit: 'meters',
          secondaryLengthUnit: 'kilometers'
          primaryAreaUnit: 'hectares',
          secondaryAreaUnit: undefined
          activeCcolor: '#ABE67E'
          completedCcolor: '#C8F2BE'
        importers:
          gml: false
          geojson: false
          kml: false
          title: ''
          content: ''
          template: '<div class="modal-header"><h2>{title}</h2></div>
                     <div class="modal-body">{content}</div>
                     <div class="modal-footer">
                       <button class="{OK_CLS}" data-editor-submit=true>{okText}</button>
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

      this.mapElement = $("<div>", class: "map")
        .insertAfter(this.element)
      this.map = L.map(this.mapElement[0],
        maxZoom: 25
        zoomControl: false
        attributionControl: false
      )

      widget = this

      this.map.on "draw:created", (e) =>
        #Attempt to add a geojson feature
        try
          feature = e.layer.toGeoJSON()
          feature.properties['internal_id'] = new Date().getTime()
          feature.properties['removable'] = true
          feature.properties['level'] = 0 if this.options.multiLevels?
          feature.properties['name'] = this.options.defaultLabel

          widget.edition.addData feature
        catch
          widget.edition.addLayer e.layer

        widget._saveUpdates()
        widget.element.trigger "mapchange"

      this.map.on "draw:edited", (e) ->
        widget._saveUpdates()
        widget.element.trigger "mapchange"

      this.map.on "draw:deleted", (e) ->
        layers = e.layers
        layers.eachLayer (layer) =>
          widget.element.trigger 'mapeditor:feature_delete', layer.feature

        widget._saveUpdates()
        widget.element.trigger "mapchange"

      this._resize()
      # console.log "resized"
      this._refreshBackgroundLayer()
      # console.log "backgrounded"
      this._refreshReferenceLayerGroup()
      # console.log "shown"
      this._refreshEditionLayerGroup()
      # console.log "edited"
      this._refreshView()
      # console.log "viewed"
      this._refreshControls()
      # console.log "controlled"

      $(this.mapElement).on 'click', '.updateAttributesInPopup', (e) =>
        e.preventDefault()
        featureId = $(e.currentTarget).closest('.leaflet-popup-content').find('*[data-internal-id]').data('internal-id')
        newName = $(e.currentTarget).closest('.popup-content').find('input[type="text"]').val()

        if this.options.multiLevels?
          level = $(e.currentTarget).closest('.popup-content').find('select').val()
          this.updateFeatureProperties(featureId, 'level', level)


        this.updateFeatureProperties(featureId, 'name', newName)

        layer = this.findLayer(featureId)

        #update popup
        this.popupize layer.feature, layer

        $(this.element).trigger('mapeditor:feature_update', layer.feature)

        widget._saveUpdates()
        $(this.element).trigger('mapchange')
        false

      widget.element.trigger "mapeditor:loaded"

    updateFeature: (feature_id, attributeName, attributeValue) ->
      this.updateFeatureProperties(feature_id, attributeName, attributeValue)
      layer = this.findLayer(feature_id)

      #update popup
      this.popupize layer.feature, layer


    updateFeatureProperties: (feature_id, attributeName, attributeValue) ->
      layer = this.findLayer(feature_id)

      if layer
        layer.feature.properties[attributeName] = attributeValue

    findLayer: (feature_id) ->
      containerLayer = undefined
      this.edition.eachLayer (layer) =>
        if (parseInt(layer.feature.properties.internal_id) == feature_id)
          containerLayer = layer
          return
      return containerLayer

    navigateToLayer: (layer) ->
      this.map.fitBounds layer.getBounds()


    removeLayer: (layer) ->
      this.edition.removeLayer layer


    popupize: (feature, layer) ->
      popup = ""
      popup += "<div class='popup-content'>"
      id = if feature.properties.id? then "#{feature.properties.id}: " else ''
      popup += "<span class='popup-block-content' data-internal-id='#{feature.properties.internal_id}'>#{id}#{feature.properties.name || this.options.defaultLabel}</span>"
      popup += "</div>"
      popup += "<div class='popup-content'>"
      popup += "<span class='popup-block-content'>#{feature.properties.type}</span>"
      popup += "</div>"
      popup += "<div class='popup-content'>"
      popup += "<input type='text' value='#{feature.properties.name || this.options.defaultLabel}'/>"

      if this.options.multiLevels?
        popup += "<select>"
        for level in [parseInt(this.options.multiLevels.minLevel)..parseInt(this.options.multiLevels.maxLevel)]
          selected = ""
          if level == parseInt(feature.properties.level)
            selected = "selected"

          popup += "<option value='#{level}' #{selected}>#{level}</option>"

        popup += "</select>"

      popup += "<input class='updateAttributesInPopup' type='button' value='ok'/>"
      popup += "</div>"

      layer.bindPopup popup

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
      if this.reference?
        this.map.removeLayer this.reference
      if this.options.show?
        if this.options.useFeatures
          this.reference = L.geoJson(this.options.show, {
            onEachFeature: (feature, layer) =>
              label = new L.Label({direction: 'auto', className:'referenceLabel'})
              label.setContent(feature.properties.name || feature.properties.id)
              label.setLatLng(layer.getBounds().getCenter())
              this.map.showLabel(label)
          })
        else
          this.reference = L.GeoJSON.geometryToLayer(this.options.show)

        this.reference.setStyle this.options.showStyle
#        this.reference = L.GeoJSON.geometryToLayer(this.options.show).setStyle this.options.showStyle
        this.reference.addTo this.map
      this

    _refreshEditionLayerGroup: ->
      if this.edition?
        this.map.removeLayer this.edition
      if this.options.edit?
        if this.options.useFeatures
          this.edition = L.geoJson(this.options.edit, {
            onEachFeature: (feature, layer) =>
              $(this.element).trigger('mapeditor:feature_add', feature)

              if feature.properties?
                this.popupize(feature, layer)

            style: (feature) =>
              levelStyle = {}

              if this.options.multiLevels?
                levelStyle = {fillColor: this.colorize(feature.properties.level)}


              $.extend(true, {}, this.options.editStyle, levelStyle)
          })
        else
          this.edition = L.GeoJSON.geometryToLayer(this.options.edit)
      else
        this.edition = L.geoJson(this.options.edit, {
          onEachFeature: (feature, layer) =>
            $(this.element).trigger('mapeditor:feature_add', feature)

            if feature.properties?
              this.popupize(feature, layer)
        })

#      this.edition.setStyle this.options.editStyle
      this.edition.addTo this.map
      this._refreshControls()
      this._saveUpdates()
      this

    buildLegend: (layers) ->
      html = ""
      levels = []
      layers.eachLayer (layer) =>
        level =  parseInt(layer.feature.properties.level)
        levels.push level if level not in levels

      levels.sort((a,b) -> b-a)

      for level in levels
        html += "<div class='leaflet-legend-item'>"
        html += "<div class='leaflet-legend-body leaflet-multilevel-legend'>"

        color = this.colorize(level)
        html += "<i style='background-color: #{color}' title='#{level}'></i>"
        html += "<span>#{level}</span>"
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
        this.map.fitBounds this.reference.getLayers()[0].getBounds()
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
        console.log view
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
        this.controls.draw = new L.Control.Draw($.extend(true, {}, this.options.controls.draw, {edit: {featureGroup: this.edition}}))
        this.map.addControl this.controls.draw
      unless this.options.controls.scale is false
        this.controls.scale = new L.Control.Scale(this.options.controls.scale)
        this.map.addControl this.controls.scale
      unless this.options.controls.measure.show is false
        this.controls.measure = new L.Control.Measure(this.options.controls.measure)
        this.map.addControl this.controls.measure
      unless this.options.controls.importers is false

        #TODO: refactor importers and make an importer bar
        unless this.options.controls.importers.gml is false
          inject =
            importer: 'gml'

          this.controls.importers_gml = new L.Control.EasyButton '<span class="leaflet-importer-gml">Gml</i>', (btn, map) =>
            args =
              title: this.options.controls.importers.title + ' ' + inject.importer.toUpperCase()
              onShow: (evt) =>
                modal = evt.modal

                modal.reloadContent(this.options.controls.importers.content, inject)

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

                $('form[data-importer-form]', modal._container).on 'ajax:success', (e) =>
                  $(e.currentTarget).find('[data-importer-spinner]').removeClass('active')

              onHide: (evt) ->
                modal = evt.modal
                $('*[data-editor-submit], *[data-editor-cancel]', modal._container).off 'click'


            map.fire 'modal', $.extend(true, {}, this.options.controls.importers, args )


        unless this.options.controls.importers.geojson is false
          inject2 =
            importer: 'geojson'

          this.controls.importers_geojson = new L.Control.EasyButton '<span class="leaflet-importer-geojson">Geojson</span>', (btn, map) =>
            args =
              title: this.options.controls.importers.title + ' ' + inject2.importer.toUpperCase()
              onShow: (evt) =>
                modal = evt.modal

                modal.reloadContent(this.options.controls.importers.content, inject2)

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

                $('form[data-importer-form]', modal._container).on 'ajax:success', (e) =>
                  $(e.currentTarget).find('[data-importer-spinner]').removeClass('active')

              onHide: (evt) ->
                modal = evt.modal
                $('*[data-editor-submit], *[data-editor-cancel]', modal._container).off 'click'


            map.fire 'modal', $.extend(true, {}, this.options.controls.importers, args )

        unless this.options.controls.importers.kml is false
          inject3 =
            importer: 'kml'

          this.controls.importers_kml = new L.Control.EasyButton '<span class="leaflet-importer-kml">KML</i>', (btn, map) =>
            args =
              title: this.options.controls.importers.title + ' ' + inject3.importer.toUpperCase()
              onShow: (evt) =>
                modal = evt.modal

                modal.reloadContent(this.options.controls.importers.content, inject3)

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

                $('form[data-importer-form]', modal._container).on 'ajax:success', (e) =>
                  #TODO: event not fired
                  $(e.currentTarget).find('[data-importer-spinner]').removeClass('active')

              onHide: (evt) ->
                modal = evt.modal
                $('*[data-editor-submit], *[data-editor-cancel]', modal._container).off 'click'


            map.fire 'modal', $.extend(true, {}, this.options.controls.importers, args )


          this.controls.importers_toolbar = new L.Control.EasyBar [this.controls.importers_gml, this.controls.importers_geojson, this.controls.importers_kml]
#          this.map.addControl this.controls.importers_geojson
#          this.map.addControl this.controls.importers_gml

          L.Control.EasyBar.addCustomClasses(this.controls.importers_toolbar, 'leaflet-importers-toolbar')

          this.controls.importers_ctrl = new L.Control.EasyButton '<i class="leaflet-importer-ctrl"></i>', (btn, map) =>

            if this.controls.importers_toolbar.options.visible
              this.controls.importers_toolbar.disable()
              this.controls.importers_toolbar.options.visible = 0
            else
              this.controls.importers_toolbar.enable()
              this.controls.importers_toolbar.options.visible = 1

          this.map.addControl this.controls.importers_ctrl

#          this.controls.importers_ctrl._container.appendChild this.controls.importers_toolbar.container
          this.map.addControl this.controls.importers_toolbar
          this.controls.importers_toolbar.options.visible = 0
          this.controls.importers_toolbar.disable()

      if this.options.multiLevels?
        this.controls.multiLevelLegend = new L.control(position: "bottomright")
        this.controls.multiLevelLegend.onAdd = (map) =>
          L.DomUtil.create('div', 'leaflet-legend-control')

        this.map.addControl this.controls.multiLevelLegend
        legend = this.controls.multiLevelLegend.getContainer()
        legend.innerHTML += this.buildLegend(this.edition)

    _saveUpdates: ->
      if this.edition?
        this.element.val JSON.stringify(this.edition.toGeoJSON())
      true

    update: ->
      this._saveUpdates()
      this.element.trigger "mapchange"

  $(document).ready ->
    $("input[data-map-editor]").each ->
      $(this).mapeditor()

) jQuery
