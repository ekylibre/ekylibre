# Add sprockets directives below:

class visualization.Color
  constructor: (color) ->
    @red   = parseInt(color.slice(1, 3), 16)
    @green = parseInt(color.slice(3, 5), 16)
    @blue  = parseInt(color.slice(5, 7), 16)

  toString: () ->
    visualization.Color.toString(this)


visualization.Color.toString = (color) ->
  return "##{visualization.Color.toHexCanal(color.red)}#{visualization.Color.toHexCanal(color.green)}#{visualization.Color.toHexCanal(color.blue)}"

visualization.Color.toHexCanal = (integer) ->
  hex = Math.round(integer).toString(16)
  if integer <= 0
    return "00"
  else if integer < 16
    return "0" + hex
  else if integer > 255
    return "FF"
  else
    return hex

visualization.Color.parse = (color) ->
  value =
    red:   parseInt(color.slice(1, 3), 16)
    green: parseInt(color.slice(3, 5), 16)
    blue:  parseInt(color.slice(5, 7), 16)
  return value

visualization.Color.random = () ->
  value =
    red:   16 * Math.round(16*Math.random())
    green: 16 * Math.round(16*Math.random())
    blue:  16 * Math.round(16*Math.random())
  return visualization.Color.toString value
