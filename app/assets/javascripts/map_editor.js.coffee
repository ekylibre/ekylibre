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
      showStyle:
        weight: 1
        color: "#333"
        fillOpacity: 0.2
      editStyle:
        weight: 2
        color: "#33A"
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
          position: 'topright'
          primaryLengthUnit: 'meters',
          secondaryLengthUnit: 'kilometers'
          primaryAreaUnit: 'hectares',
          secondaryAreaUnit: undefined
          activeCcolor: '#ABE67E'
          completedCcolor: '#C8F2BE'
        importers:
          gml: true
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

      this.map.on "draw:created", (e) ->
        widget.edition.addLayer e.layer
        widget._saveUpdates()
        widget.element.trigger "mapchange"

      this.map.on "draw:edited", (e) ->
        widget._saveUpdates()
        widget.element.trigger "mapchange"

      this.map.on "draw:deleted", (e) ->
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

      widget.element.trigger "mapeditor:loaded"


    findLayer: (feature_id) ->
      containerLayer = undefined
      this.edition.eachLayer (layer) =>
        if (layer.feature.properties.internal_id == feature_id)
          containerLayer = layer
          return
      return containerLayer

    navigateToLayer: (layer) ->
      this.map.fitBounds layer.getBounds()

    onEachFeature: (feature, layer) ->
      $(document).trigger('mapeditor:feature_add', [feature, layer])

      if (feature.properties && feature.properties.type?)
        popup = ""
        popup += "<div class='popup-content'>"
        popup += "<span class='popup-block-content'>#{feature.properties.type}: #{feature.properties.name}</span>"
        popup += "</div>"

        layer.bindPopup popup

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
        this.reference = L.GeoJSON.geometryToLayer(this.options.show).setStyle this.options.showStyle
        this.reference.addTo this.map
      this

    _refreshEditionLayerGroup: ->
      if this.edition?
        this.map.removeLayer this.edition
      if this.options.edit?
#        this.edition = L.GeoJSON.geometryToLayer(this.options.edit)
        this.edition = L.geoJson(this.options.edit, {
          onEachFeature: this.onEachFeature
        })
      else
        this.edition = new L.GeoJSON()

      this.edition.setStyle this.options.editStyle
      this.edition.addTo this.map
      this._refreshControls()
      this._saveUpdates()
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
      unless this.options.controls.measure is false
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


    _saveUpdates: ->
      if this.edition?
        this.element.val JSON.stringify(this.edition.toGeoJSON())
      true

  $(document).ready ->
    $("input[data-map-editor]").each ->
      $(this).mapeditor()

) jQuery
