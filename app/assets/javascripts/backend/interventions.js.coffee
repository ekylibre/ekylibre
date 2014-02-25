(($) ->
  'use strict'

  # Interventions permit to enhances data input through context computation
  # The concept is: When an update is done, we ask server which are the impact on
  # other fields and on updater itself if necessary
  $.interventions =
    serialize: (procedure) ->
      casting = {}
      $("*[data-procedure='#{procedure}'][data-variable-handler]").each (index) ->
        element = $(this)
        casting[element.data('variable')] ?= {}
        casting[element.data('variable')].handlers ?= {}
        if element.prop("map")?
          map = element.prop("map")
          value = map.editedLayer.toGeoJSON()
        else
          value = element.val()
        casting[element.data('variable')].handlers[element.data('variable-handler')] = value

      $("*[data-procedure='#{procedure}'][data-variable-destination]").each (index) ->
        element = $(this)
        casting[element.data('variable')] ?= {}
        casting[element.data('variable')].destinations ?= {}
        casting[element.data('variable')].destinations[element.data('variable-destination')] = element.val()

      $("*[data-procedure='#{procedure}'][data-variable-actor]").each (index) ->
        element = $(this)
        casting[element.data('variable')] ?= {}
        if this.hiddenInput?
          casting[element.data('variable')].actor = this.hiddenInput.val()
        else
          casting[element.data('variable')].actor = $(this).val()

      $("*[data-procedure='#{procedure}'][data-variable-variant]").each (index) ->
        element = $(this)
        casting[element.data('variable')] ?= {}
        if this.hiddenInput?
          casting[element.data('variable')].variant = this.hiddenInput.val()
        else
          casting[element.data('variable')].variant = $(this).val()

      casting

    unserialize: (procedure, casting) ->
      for variable, attributes of casting
        if attributes.actor?
          $("*[data-procedure='#{procedure}'][data-variable-actor='#{variable}']").each (index) ->
            if this.hiddenInput? and attributes.actor != parseInt this.hiddenInput.val()
              $.EkylibreSelector.set($(this), attributes.actor)
            else if attributes.actor != parseInt $(this).val()
              $(this).val(attributes.actor)
                
        if attributes.variant?
          $("*[data-procedure='#{procedure}'][data-variable-variant='#{variable}']").each (index) ->
            if this.hiddenInput? and attributes.variant != parseInt this.hiddenInput.val()
              $.EkylibreSelector.set($(this), attributes.variant)
            else if attributes.variant != parseInt $(this).val()
              $(this).val(attributes.variant)
                
        if attributes.handlers?
          for handler, value of attributes.handlers
            $("*[data-procedure='#{procedure}'][data-variable='#{variable}'][data-variable-handler='#{handler}']").each (index) ->
              if $(this).prop("map")? # test if shape is different too
                map = $(this).prop("map")
                map.editedLayer.clearLayers()
                layer = L.GeoJSON.geometryToLayer(value).setStyle(
                  weight: 1
                  color: "#333"
                ).addTo map
                map.editedLayer.addLayer layer
                map.fitBounds(map.editedLayer.getBounds())
              else if value != parseFloat $(this).val()
                $(this).val(value)
                
        if attributes.destinations?
          for destination, value of attributes.destinations
            $("*[data-procedure='#{procedure}'][data-variable='#{variable}'][data-variable-destination='#{destination}']").val(value)
      

    refresh: (origin) ->
      procedure = origin.data('procedure')
      computing = $("*[data-procedure-computing='#{procedure}']").first?()
      unless computing.prop('waiting')
        # Serialize data
        intervention =
          procedure: procedure
          updater: origin.data('intervention-updater')
          casting: $.interventions.serialize(procedure) 
        # Ask server for reverberated updates
        $.ajax
          url: computing.val()
          data: intervention
          beforeSend: ->
            computing.prop 'waiting', true
          error: (request, status, error) ->
            computing.prop 'waiting', false          
          success: (data, status, request) ->
            # Updates elements with new values
            computing.prop 'waiting', false
            $.interventions.unserialize(procedure, data)
            console.log "Updates other items"


  ##############################################################################
  # Triggers
  $(document).on 'keyup', '*[data-variable-handler]', ->
    $(this).each ->
      $.interventions.refresh($(this))

  $(document).on 'change', '*[data-variable-actor]', ->
    $(this).each ->
      $.interventions.refresh($(this))

  $(document).on 'change', '*[data-variable-variant]', ->
    $(this).each ->
      $.interventions.refresh($(this))

  true
) jQuery
