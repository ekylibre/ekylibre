# The scheduler allows to render a layerGroup at a specified level (compared to others).
# It "schedules" the layerGroup i.e. it replays layerGroup's rendering to the right time.
L.LayersScheduler = L.Class.extend

  # flow is an array of layerGroup ids
  initialize: (flow = [], options = {}) ->
    L.Util.setOptions @, options
    @flow = flow


  addTo: (map) ->
    @_map = map

  insert: (id, options = {}) ->
    if options.back then @flow.unshift(id) else @flow.push(id)
    @flow

  # Note: if layer not found in the flow, we consider to let it in top.
  schedule: (layerGroup = undefined) ->

    if layerGroup and layerGroup._leaflet_id
      index = @flow.indexOf(layerGroup._leaflet_id)

      # unless layerGroup to schedule is already the last element
      unless index == -1 or index == @flow.length - 1
        # we need to find the next element to place it before
        nextSibling = @_map._layers[@flow[index + 1]]

        # to do that, we need to iterate until finding geometry layer and its first svg path
        if nextSibling and nextSibling.getLayers().length
          # as a ILayer (including feature layer)
          objectLayer = nextSibling

          loop
            break unless (objectLayer and Object.keys(objectLayer._layers || []).length) or not objectLayer._latlngs
            objectLayer = objectLayer.getLayers()[0]

          layerGroup.bringBefore objectLayer._container if objectLayer._container

    else
      #redraw all ?

# factory
L.layersScheduler = (flow = [], options = {}) ->
  new L.LayersScheduler(flow, options)


L.LayerGroup.include
  bringBefore: (node) ->
    @invoke 'bringBefore', node

L.Path.include
  bringBefore: (node) ->
    root = @_map._pathRoot
    path = @_container
    root.insertBefore path, node

