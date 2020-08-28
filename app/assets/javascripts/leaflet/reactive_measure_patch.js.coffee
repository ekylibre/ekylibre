L.Draw.Polyline.include
  ___vertexChanged: L.Draw.Polyline.prototype.__vertexChanged

  _vertexChanged: () ->
    @___vertexChanged.apply this, arguments
    @_map.closeTooltip(@_tooltip)
    # @_tooltip.hide()


  __onMouseMove: (e) ->
    @_map.closeTooltip(@_tooltip) if @_tooltip?
    # @_tooltip.hide() if @_tooltip?
    return unless @_markers.length > 0
    newPos = @_map.mouseEventToLayerPoint(e.originalEvent)
    mouseLatLng = @_map.layerPointToLatLng(newPos)

    latLngArray = []
    for latLng in @_poly.getLatLngs()
      latLngArray.push latLng
    latLngArray.push mouseLatLng

    # draw a polyline
    if @_markers.length == 1
      clone = L.polyline latLngArray

    # draw a polygon
    if @_markers.length >= 2
      clone = L.polygon latLngArray

    clone._map = @_map
    center = clone.__getCenter()

    measure =  L.GeographicUtil.Polygon clone.getLatLngsAsArray()

    e.target.reactiveMeasureControl.updateContent measure, {selection: true}
