((E, $) ->
  "use strict";

  class LocationUtils
    findGetParameter: (parameterName) ->
      result = null
      tmp = []

      location
        .search
        .substr(1)
        .split("&")
        .forEach (item) ->
          tmp = item.split("=")

          if (tmp[0] == parameterName)
            result = decodeURIComponent(tmp[1])

      return result


  E.locationUtils = new LocationUtils()

  true
) ekylibre, jQuery
