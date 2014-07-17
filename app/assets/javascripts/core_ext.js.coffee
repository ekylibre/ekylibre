# Core extension for vizualisation
#
String.prototype.camelize = () ->
  array = jQuery.map this.split("_"), (word)->
    word.charAt(0).toUpperCase() + word.slice(1)
  return array.join()

String.prototype.repeat = (count) ->
  return new Array(count + 1).join(this)

Math.magnitude = (number, step = 1) ->
  value = Math.abs(number)
  power = 0
  if value > 1
    while Math.pow(10, power + step) < value
      power += step
  else
    while Math.pow(10, power - step) > value
      power -= step
  mag = Math.pow(10, power)
  result =
    power: power
    magnitude: mag
    base: number / mag

Math.round2 = (number, round = 1) ->
  return round * Math.round(number / round)

Math.humanize = (value, power = 0) ->
  return Math.round(value)
  # return Math.round(value / Math.pow(10, power)) + "e#{power}"
  size = Math.round(power / 3)
  return Math.round(value / Math.pow(10, 3 * size)) + "pnµm KMGTPE"[size + 4]

Math.ceil2 = (number, round = 1) ->
  return round * Math.ceil(number / round)

Math.floor2 = (number, round = 1) ->
  return round * Math.floor(number / round)

