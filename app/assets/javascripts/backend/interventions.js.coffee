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
        if element.is(":ui-selector")
          casting[element.data('variable')].actor = element.selector("value")
        else
          casting[element.data('variable')].actor = element.val()

      $("*[data-procedure='#{procedure}'][data-variable-variant]").each (index) ->
        element = $(this)
        casting[element.data('variable')] ?= {}
        if element.is(":ui-selector")
          casting[element.data('variable')].variant = element.selector("value")
        else
          casting[element.data('variable')].variant = element.val()

      casting

    unserialize: (procedure, casting) ->
      console.log "Unserialize!"
      for variable, attributes of casting
        if attributes.actor?
          $("*[data-procedure='#{procedure}'][data-variable-actor='#{variable}']").each (index) ->
            element = $(this)
            if element.is(":ui-selector")
              if attributes.actor != element.selector("value")
                element.selector("value", attributes.actor)
            else if attributes.actor != parseInt element.val()
              element.val(attributes.actor)
                
        if attributes.variant?
          $("*[data-procedure='#{procedure}'][data-variable-variant='#{variable}']").each (index) ->
            element = $(this)
            if element.is(":ui-selector")
              if attributes.variant != element.selector("value")
                element.selector("value", attributes.actor)
            else if attributes.variant != parseInt element.val()
              element.val(attributes.variant)
                
        if attributes.handlers?
          for handler, value of attributes.handlers
            $("*[data-procedure='#{procedure}'][data-variable='#{variable}'][data-variable-handler='#{handler}']").each (index) ->
              if $(this).is(":ui-mapeditor")
                $(this).mapeditor "show", value
                $(this).mapeditor "edit", value
                try
                  $(this).mapeditor "view", "edit"
              else if value != parseFloat $(this).val()
                $(this).val(value)
                
        if attributes.destinations?
          for destination, value of attributes.destinations
            $("*[data-procedure='#{procedure}'][data-variable='#{variable}'][data-variable-destination='#{destination}']").each (index) ->
              # TODO: Find a better way later to manage different datatypes like geometry
              if destination is 'shape'
                $(this).val(JSON.stringify(value))
              else
                $(this).val(value)
      

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
  $(document).on 'keyup mapchange', '*[data-variable-handler]', ->
    console.log "Handler change!"
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
