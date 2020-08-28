###
# Extend L.Tooltip to provide a label on centroid, calculated from a L.Latlng[]
# options:
#   toBack {boolean} if true, label is set to objectsPane, allowing to be covered by higher level pane
#   opacity: {string} ([0..1] | 'inherit') inherit allows to use opacity in your class. Default: 'inherit'
 ###
L.GhostLabel = L.Tooltip.extend
  __initialize: L.Tooltip::initialize
  _onAdd: L.Tooltip.prototype.onAdd
  __setOpacity: L.Tooltip::setOpacity

  initialize: (options, source) ->
    options.opacity ||= 'inherit'
    options.direction ||= 'center'
    options.permanent ||= 'true'

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
      unless map.getPane('objectsPane')
        map.createPane('objectsPane').style.zIndex = 300
      @options.pane = 'objectsPane'


    @_onAdd.apply this, arguments

    map.on 'zoomend', @_onZoomEnd, @

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

  updateZIndex: (zIndex)->
    @_zIndex = zIndex

    if (@_container && @._zIndex)
      @_container.style.zIndex = zIndex

L.extendedMethods =
  # Allow to be updated
  bindGhostLabel: (object, options) ->

    if !@label
      @label = object
      @_tooltip = object

    return
  
  updateLabelContent: (content) ->
    if @label
      @setTooltipContent(content)

L.Polygon.include L.extendedMethods
L.FeatureGroup.include L.extendedMethods

