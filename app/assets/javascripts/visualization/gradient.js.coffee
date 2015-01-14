# Add sprockets directives below:
#

# Computes grades for a given
class visualization.Gradient

  constructor: (data, property, options = {}) ->
    options.round       ?= 5
    options.levelNumber ?= 7

    # Default values
    @round       ?= options.round
    @levelNumber ?= options.levelNumber

    # Find min and max values
    @grades   = []
    if data[0]
      @maxValue = data[0][property]
      @minValue = data[0][property]
      for zone in data
        if zone[property] > @maxValue
          @maxValue = zone[property]
        if zone[property] < @minValue
          @minValue = zone[property]
      if @maxValue == @minValue
        console.warn "Force max value to be different of min value"
        @maxValue += 1
    else
      console.warn "Sets default min and max without data"
      @maxValue = 10
      @minValue = 0
    console.log "Exact min (#{@minValue}) and max (#{@maxValue}) computed"

    # Simplify values
    maxMagnitude = Math.magnitude(@maxValue)
    minMagnitude = Math.magnitude(@minValue)
    ref = minMagnitude
    if maxMagnitude.power > minMagnitude.power
      ref = maxMagnitude
    @power = ref.power
    mag = ref.magnitude
    mag = mag / 10 if mag >= 100
    @maxValue = Math.ceil2(@maxValue,  mag * @round)
    @minValue = Math.floor2(@minValue, mag * @round)
    @length = @maxValue - @minValue

    if @length > 0
      if @levelNumber > @length and @length > 2
        @levelNumber = @length
      console.log "Min (#{@minValue}) and max (#{@maxValue}) computed"

      # Compute grades
      for g in [1..@levelNumber]
        grade =
          index: (g-1)
          min: @minValue + (g-1) * @length / @levelNumber
          max: @minValue +  g    * @length / @levelNumber
        grade.minLabel = Math.humanize(grade.min, @power)
        grade.maxLabel = Math.humanize(grade.max, @power)
        @grades.push grade
      console.log "Grades computed"

  # Returns the grade for the given value
  gradeFor: (value) ->
    level = Math.round(@levelNumber * (value - @minValue) / @length)
    level = @levelNumber - 1 if level >= @levelNumber
    level = 0 if level < 0 or isNaN(level)
    return @grades[level]

  # Returns if the gradient is valid
  valid: () ->
    @length > 0
