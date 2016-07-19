###
# Provides clustering for GhostLabels

# options:
#   type {string} ('number' || 'hidden') if number, display count of collapsed items inside a group. If hide, collapsed items are hidden.
#   className {string} Overrides container class name. By default, it inherits from layer
#   innerClassName {string} Set a custom inner class name
#   margin: {number (as px)} Wrap labels in a margin box, considering as the clustering limits. Default: 0
#
#
# Thanks to LayerGroup.collision for inspiration https://github.com/MazeMap/Leaflet.LayerGroup.Collision
# Thanks to RBush for awesome lib https://github.com/mourner/rbush
#
 ###

L.GhostLabelCluster = L.LayerGroup.extend
  __initialize: L.LayerGroup::initialize
  __addLayer: L.LayerGroup::addLayer
  __removeLayer: L.LayerGroup::removeLayer
  __clearLayers: L.LayerGroup::clearLayers

  initialize: (options) ->
    L.setOptions @, options
    @_originalLayers =  []
    @_clusterIndex = []
    @_visibleLayers = {}
    @_rbush = []
    @_cachedRelativeBoxes = []
    @_margin = 0
    @__initialize.call @, options
    @_margin = options.margin or 0
    @_rbush = null
    return

  addLayer: (layer) ->
    @_originalLayers.push layer unless @_originalLayers.indexOf(layer) != -1
    if @_map
      @__addClusteredLayer layer
    return

  bind: (layer, parent) ->
    @addLayer layer

    if @_originalLayers.indexOf(layer) != -1
      # To be updated when feature name change
      parent.bindGhostLabel layer
      parent.on 'remove', @removeLayer, @


  removeLayer: (e) ->
    layer = e.target.label
    @_rbush.remove @_cachedRelativeBoxes[layer._leaflet_id]
    delete @_cachedRelativeBoxes[layer._leaflet_id]

    i = @_originalLayers.indexOf(layer)
    if i != -1
      @_originalLayers.splice i, 1

    delete @_visibleLayers[layer._leaflet_id]
    @__removeLayer.call @, layer

    return

  clearLayers: ->
    @_rbush = rbush()
    _clusterIndex: []
    @_originalLayers = []
    @_visibleLayers = {}
    @_cachedRelativeBoxes = []
    @__clearLayers.call this
    return

  onAdd: (map) ->
    unless @_map
      @_map = map
      @refresh()
      map.on 'zoomend', @refresh, this
    return

  onRemove: (map) ->
    map.off 'zoomend', @refresh, this
    return

  __addClusteredLayer: (layer) ->
    className = if @options.className? then @options.className else layer.options.className
    innerClass = if @options.innerClassName? then @options.innerClassName else ''

    bush = @_rbush

    box = @_cachedRelativeBoxes[layer._leaflet_id]
    visible = false
    if !box
      # Add the layer to the map so it's instantiated on the DOM,
      #   in order to fetch its position and size.
      @__addLayer.call @, layer
      visible = true

      box = @_getContainerBox(layer._container)

      @_cachedRelativeBoxes[layer._leaflet_id] = box

    box = @_positionBox(@_map.latLngToLayerPoint(layer.getLatLng()), box)

    # Search collisions from absolute position
    collidedItems = bush.search(box)

    # Add reference to layer to track collided layers. Take advantage of rbush properties
    box.push id: layer._leaflet_id

    if collidedItems.length is 0
      if !visible
        @__addLayer.call @, layer
      @_visibleLayers[layer._leaflet_id] = layer
      bush.load [box]
    else
      @__removeLayer.call @, layer
      # Layers which collided
      latLngBounds = new L.LatLngBounds
      latLngBounds.extend layer.getLatLng()

      idsToCollapse = []
      for item in collidedItems
        otherLayer = @getLayer(item[4].id)

        if otherLayer
          bounds = otherLayer.getLatLng()
          @__removeLayer.call @, otherLayer
          idsToCollapse.push otherLayer._leaflet_id
        else
          collapsedLayer = @_visibleLayers[@_clusterIndex[item[4].id]]
          bounds = collapsedLayer.getLatLng() unless collapsedLayer is undefined

        latLngBounds.extend bounds unless bounds is undefined


      collapsedLayer ||= new L.GhostLabel(className: className)

      collapsedLayer.setLatLng latLngBounds.getCenter()


      # add to this layer group
      @__addLayer.call @, collapsedLayer

      @_visibleLayers[collapsedLayer._leaflet_id] = collapsedLayer


      # clustering track
      @_clusterIndex[layer._leaflet_id] = collapsedLayer._leaflet_id
      for id in idsToCollapse
        @_clusterIndex[id] = collapsedLayer._leaflet_id

      if @options.type is 'number'
        count = @_clusterIndex.filter((i) -> i == collapsedLayer._leaflet_id).length
        collapsedLayer.setContent("<span class='#{innerClass}'>#{count}</span>")

        collapsedLayer.setLatLng latLngBounds.getCenter()


    return

  _getContainerBox: (el) ->
    styles = window.getComputedStyle(el)
    [
      parseInt(styles.marginLeft)
      parseInt(styles.marginTop)
      parseInt(styles.marginLeft) + parseInt(styles.width)
      parseInt(styles.marginTop) + parseInt(styles.height)
    ]

  _positionBox: (offset, box) ->
    [
      box[0] + offset.x - (@_margin)
      box[1] + offset.y - (@_margin)
      box[2] + offset.x + @_margin
      box[3] + offset.y + @_margin
    ]

  refresh: ->
    for id, layer of @_visibleLayers
      @__removeLayer.call @, layer
      delete @_visibleLayers[id]

    @_rbush = rbush()

    for layer in @_originalLayers
      @__addClusteredLayer layer
    return


L.ghostLabelCluster  = (options) ->
  new (L.GhostLabelCluster)(options or {})

