#= require map_editor
beforeEach ->
  @map = new L.Map(document.createElement('div')).setView [0, 0], 15

describe 'L.Draw.Polyline.ReactiveMeasure', ->
  beforeEach ->
    @geod = GeographicLib.Geodesic.WGS84
    @drawnItems = new L.FeatureGroup().addTo(@map)
    @edit = new L.EditToolbar.Edit @map,
      featureGroup: @drawnItems
      poly: allowIntersection: false
      selectedPathOptions: L.EditToolbar::options.edit.selectedPathOptions
    return

  it 'should draw a polyline', ->
#    @drawnItems.addLayer @poly
    @edit.enable()
    @poly = new L.Draw.Polyline @map
    @poly.addHooks()

    latlng = L.latLng(44.859585, -0.564652)
    @poly._markers.push(@poly._createMarker(latlng))
    @poly._poly.addLatLng(latlng)

    latlng = L.latLng(42, -88)
    @poly._markers.push(@poly._createMarker(latlng))
    @poly._poly.addLatLng(latlng)

    latlngs = @poly._poly.getLatLngsAsArray()
    r = L.GeographicUtil.distance(latlngs[1], latlngs[0])


  # test if a polygon is drawn and if perimeter and area match
  it 'should draw a polygon', ->
    # generate a square coordinates
    square = window.Tools.squareFrom([44.93042508, -0.58050000], 10e3)

    poly = new L.Draw.Polygon @map
    poly.addHooks()

    for latlng in square
      latlng = L.latLng latlng
      poly._markers.push poly._createMarker(latlng)
      poly._poly.addLatLng latlng


    expect(poly.type).toBe('polygon')


    latlngs = []
    for latlng in square
      latlng = L.latLng latlng
      latlngs.push latlng

#
#    @edit.enable()
#    poly = new L.Polygon latlngs
#    @drawnItems.addLayer poly
#    console.log poly, @drawnItems
#    expect(@drawnItems.getLayer(poly._leaflet_id)).not.toBe(undefined)



    g = new L.GeographicUtil.Polygon(square)
    console.log g.perimeter().toFixed(3) + " " + g.area().toFixed(1)

#    @drawnItems.addLayer poly

#    @edit.enable()


    polygon = @geod.Polygon(false)
    for marker in poly._markers
      point = marker.getLatLng().toArray()
      polygon.AddPoint point[0], point[1]

    polygon = polygon.Compute(false, true)
    expect(polygon.perimeter).toBe(g.perimeter())
    expect(polygon.area).toBe(g.area())

