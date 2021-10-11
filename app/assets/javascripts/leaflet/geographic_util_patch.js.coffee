class L.GeographicUtil
  @Polygon: (points, polyline = false) -> # (Array of [lat,lng] pair)
    geod = GeographicLib.Geodesic.WGS84
    
    poly = geod.Polygon(false)
    for point in points
      poly.AddPoint point[0], point[1]

    poly = poly.Compute(false, true)

    poly2 = geod.Polygon(true)
    for point in points
      poly2.AddPoint point[0], point[1]

    poly2 = poly2.Compute(false, true)

    extrapolatedArea = Math.abs(poly.area)

    extrapolatedPerimeter: poly.perimeter,
    extrapolatedArea: extrapolatedArea,
    area: extrapolatedArea,
    perimeter: poly2.perimeter