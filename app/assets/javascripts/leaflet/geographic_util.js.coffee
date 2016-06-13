L.GeographicUtil = L.extend L.GeographicUtil || {},
  geod: GeographicLib.Geodesic.WGS84

# Use Karney distance formula
# ([lat, lng], [lat, lng]) -> Number (in meters)
  distance: (a, b) ->
    r = @geod.Inverse(a[0], a[1], b[0], b[1])
    r.s12.toFixed(3)

  Polygon: (points) -> # (Array of [lat,lng] pair)
    @geod = GeographicLib.Geodesic.WGS84
    @poly = @geod.Polygon(false)
    for point in points
      @poly.AddPoint point[0], point[1]

    @poly = @poly.Compute(false, true)
    return

L.GeographicUtil.Polygon.prototype =
  perimeter: ->
    @poly.perimeter
  area: ->
    Math.abs @poly.area
