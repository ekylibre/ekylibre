###
# Extend L.Label to provide a label on centroid, calculated from a L.Latlng[]
# options:
#   toBack {boolean} if true, label is set to objectsPane, allowing to be covered by higher level pane
#   opacity: {string} ([0..1] | 'inherit') inherit allows to use opacity in your class. Default: 'inherit'
 ###
L.GhostLabel = L.Label.extend
  __initialize: L.Label::initialize
  _onAdd: L.Label.prototype.onAdd
  __updateContent: L.Label.prototype._updateContent
  __setOpacity: L.Label::setOpacity

  initialize: (options, source) ->
    options.opacity ||= 'inherit'

    @__initialize.apply @, arguments

  ###
  # Set the latLng[] to calculate the centroid
   ###
  toCentroidOfBounds: (latLngs) ->
    # To center of bounds if centroid can't be calculated during onAdd
    @_latlng = L.latLngBounds(latLngs).getCenter()
    @_latLngs = latLngs
    return this

  onAdd: (map) ->
    # Don't hide labels on click
    @options.noHide = true

    if @options.toBack
      @options.pane = 'objectsPane'

    @_onAdd.apply this, arguments

    map.on 'zoomend', @_onZoomEnd, @

    if @options.toBack
      # ZIndex 3 is default index of objectsPane
      @updateZIndex '3'

      @_updatePosition()
    return

  setOpacity: (opacity) ->
    unless opacity is 'inherit'
      @__setOpacity.call @, opacity

  getLatLng: ->
    @_latlng

  _onZoomEnd: (e) ->
    @getCenter(e.target)

  getCenter: (map)->
    if @_latLngs
      poly = L.polygon(@_latLngs)
      poly._map = @_map || map
      @_latlng = poly.__getCenter()

    @_latlng


  ###
  # Override to set position on pos, considering label center
   ###
  _setPosition: (pos) ->
    map = @_map
    container = @_container
    labelWidth = @_labelWidth
    labelHeight = @_labelHeight || 0

    pos = pos.add(L.point(-labelWidth/2, -labelHeight/2))
    L.DomUtil.setPosition container, pos
    return

  ###
  #  Override to set position on pos, considering label center
   ###
  _updateContent: ->
    @__updateContent.call this
    @_labelHeight = @_container.offsetHeight if @_container


L.extendedMethods =
  # Allow to be updated
  bindGhostLabel: (object, options) ->

    if !@label
      @label = object

    if !@_showLabelAdded
      @on 'remove', @_hideLabel, @

    @_showLabelAdded = true
    return

L.Polygon.include L.extendedMethods
L.FeatureGroup.include L.extendedMethods

