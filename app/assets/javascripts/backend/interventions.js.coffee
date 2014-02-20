(($) ->
  'use strict'
  $.readings =
    individual: (indicatorName, actor) ->
      1.0

    whole: (indicatorName, actor) ->
      1.0

    individualMeasure: (indicatorName, actor, unit) ->
      1.0

    wholeMeasure: (indicatorName, actor, unit) ->
      1.0

  class $.Procedure
    constructor: (@name) ->

    actor: (name) ->
      new $.Actor(@name, name)

  class $.Actor
    constructor: (@procedure, @name) ->

    getValue: (indicatorName, options = {}) ->
      # Find input
      # Get ID of selected product
      # If new, only "needed" indicator are available
      # Cache ?!
      1.0

    individual: (indicatorName) ->
      this.getValue(indicatorName, whole: false)

    whole: (indicatorName) ->
      this.getValue(indicatorName, whole: true)

    individualMeasure: (indicatorName, unit) ->
      this.getValue(indicatorName, whole: false, unit: unit)

    wholeMeasure: (indicatorName, unit) ->
      this.getValue(indicatorName, whole: true, unit: unit)

  $.procedures =
    procedure:
      findActor: (name) ->
        new $.Actor(name)

  true
) jQuery
