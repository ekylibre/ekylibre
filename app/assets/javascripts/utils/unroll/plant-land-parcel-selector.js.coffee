((E, $) ->
  'use strict'

  $(document).ready ->


    class PlantLandParcelSelector
      ACTIVITY_PRODUCTION_PARAM_NAME: 'of_activity_production'
      WITH_ID_PARAM_NAME: 'with_id'

      PLANT_VALUE: 'plant'
      LAND_PARCEL_VALUE: 'land_parcel'

      PLANT_UNROLL_VALUE: 'is+plant+and+has+indicator+shape'
      LAND_PARCEL_UNROLL_VALUE: 'is+land_parcel+and+has+indicator+shape'

      constructor: ->


      changeUnrollUrl: (event, unrollElement, supportId = null, activityProduction = null) ->
        selectedValue = $(event.target).val()
        unrollExpression = @PLANT_UNROLL_VALUE
        unrollExpression = @LAND_PARCEL_UNROLL_VALUE if selectedValue == @LAND_PARCEL_VALUE

        unrollRegex = /(unroll\?.*scope.*of_expression[^=]*)=([^&]*)(&?.*)/
        unrollPath = $(unrollElement).attr('data-selector')
        unrollPath = unrollPath.replace(unrollRegex, "$1=#{ unrollExpression }$3")

        ofActivityProduction = unrollPath.includes(@ACTIVITY_PRODUCTION_PARAM_NAME)
        withId = unrollPath.includes(@WITH_ID_PARAM_NAME)

        if selectedValue == @LAND_PARCEL_VALUE
          $(unrollElement).attr('data-selector', unrollPath) unless ofActivityProduction
          $(unrollElement).attr('data-selector', this._unrollPathWithScope(unrollPath, @ACTIVITY_PRODUCTION_PARAM_NAME, supportId)) if ofActivityProduction
          $($(unrollElement)[0]).selector('value', supportId)

        else if selectedValue == @PLANT_VALUE
          $(unrollElement).attr('data-selector', unrollPath) unless withId
          $(unrollElement).attr('data-selector', this._unrollPathWithScope(unrollPath, @WITH_ID_PARAM_NAME, activityProduction)) if withId

          $(unrollElement).val(null)
          $(unrollElement).closest('.selector').find('.selector-value').val(null)

        $(unrollElement).trigger 'selector:set'


      _unrollPathWithScope: (unrollPath, paramName, paramValue) ->
        unrollPathBegin = unrollPath.split(paramName)[0]
        scope = "#{ paramName }=#{ paramValue }$3"

        unrollPathBegin + scope


    E.PlantLandParcelSelector = PlantLandParcelSelector

) ekylibre, jQuery
