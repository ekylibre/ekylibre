(($) ->
  'use strict'

  $.procedures =
    refresh: (origin) ->
      # Serialize object
      procedure = origin.data('procedure')
      computing = $("*[data-procedure-computing='#{procedure}']").first?()

      unless computing.prop('waiting')
        intervention =
          procedure: procedure
          updater: origin.data('intervention-updater')
          casting: {}

        $("*[data-procedure='#{procedure}'][data-variable-handler]").each (index) ->
          element = $(this)
          intervention.casting[element.data('variable')] ?= {}
          intervention.casting[element.data('variable')].handlers ?= {}
          intervention.casting[element.data('variable')].handlers[element.data('variable-handler')] = element.val()
          true

        $("*[data-procedure='#{procedure}'][data-variable-destination]").each (index) ->
          element = $(this)
          intervention.casting[element.data('variable')] ?= {}
          intervention.casting[element.data('variable')].destinations ?= {}
          intervention.casting[element.data('variable')].destinations[element.data('variable-destination')] = element.val()
          true

        $("*[data-procedure='#{procedure}'][data-variable-actor]").each (index) ->
          element = $(this)
          intervention.casting[element.data('variable')] ?= {}
          if this.hiddenInput?
            intervention.casting[element.data('variable')].actor = this.hiddenInput.val()
          else
            intervention.casting[element.data('variable')].actor = $(this).val()
          true

        $("*[data-procedure='#{procedure}'][data-variable-variant]").each (index) ->
          element = $(this)
          intervention.casting[element.data('variable')] ?= {}
          if this.hiddenInput?
            intervention.casting[element.data('variable')].variant = this.hiddenInput.val()
          else
            intervention.casting[element.data('variable')].variant = $(this).val()
          true
        # Send to server
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
            for variable, attributes of data
              if attributes.actor?
                $("*[data-procedure='#{procedure}'][data-variable-actor='#{variable}']").each (index) ->
                  if this.hiddenInput?
                    if attributes.actor != parseInt this.hiddenInput.val()
                      $.EkylibreSelector.set($(this), attributes.actor)
                  else
                    if attributes.actor != parseInt $(this).val()
                      $(this).val(attributes.actor)
              if attributes.variant?
                $("*[data-procedure='#{procedure}'][data-variable-variant='#{variable}']").each (index) ->
                  if this.hiddenInput?
                    if attributes.variant != parseInt this.hiddenInput.val()
                      $.EkylibreSelector.set($(this), attributes.variant)
                  else
                    if attributes.variant != parseInt $(this).val()
                      $(this).val(attributes.variant)
              if attributes.handlers?
                for handler, value of attributes.handlers
                  $("*[data-procedure='#{procedure}'][data-variable='#{variable}'][data-variable-handler='#{handler}']").each (index) ->
                    if value != parseFloat $(this).val()
                      $(this).val(value)
              if attributes.destinations?
                for destination, value of attributes.destinations
                  $("*[data-procedure='#{procedure}'][data-variable='#{variable}'][data-variable-destination='#{destination}']").val(value)
            console.log "Updates other items"

  $(document).on 'keyup', '*[data-variable-handler]', ->
    $.procedures.refresh($(this))

  $(document).on 'change', '*[data-variable-actor]', ->
    $(this).each ->
      $.procedures.refresh($(this))

  $(document).on 'change', '*[data-variable-variant]', ->
    $(this).each ->
      $.procedures.refresh($(this))

  true
) jQuery
