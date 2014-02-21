(($) ->
  'use strict'

  $.procedures =
    refresh: (origin) ->
      # Serialize object
      procedure = origin.data('procedure')
      computing = $('*[data-procedure-computing="' + procedure + '"]').first?()

      unless computing.prop('waiting')
        intervention =
          procedure: procedure
          updater: origin.data('intervention-updater')
          casting: {}

        $('*[data-procedure="' + procedure + '"][data-variable-handler]').each (index) ->
          element = $(this)
          intervention.casting[element.data('variable')] ?= {}
          intervention.casting[element.data('variable')].handlers ?= {}
          intervention.casting[element.data('variable')].handlers[element.data('variable-handler')] = element.val()
          true

        $('*[data-procedure="' + procedure + '"][data-variable-destination]').each (index) ->
          element = $(this)
          intervention.casting[element.data('variable')] ?= {}
          intervention.casting[element.data('variable')].destinations ?= {}
          intervention.casting[element.data('variable')].destinations[element.data('variable-destination')] = element.val()
          true

        $('*[data-procedure="' + procedure + '"][data-variable-actor]').each (index) ->
          element = $(this)
          intervention.casting[element.data('variable')] ?= {}
          intervention.casting[element.data('variable')].actor = this.hiddenInput.val()
          true

        $('*[data-procedure="' + procedure + '"][data-variable-variant]').each (index) ->
          element = $(this)
          intervention.casting[element.data('variable')] ?= {}
          intervention.casting[element.data('variable')].variant = this.hiddenInput.val()
          true
        # Send to server
        $.ajax
          url: computing.val()
          data: intervention
          beforeSend: ->
            computing.prop 'waiting', true
          success: (data, status, request) ->
            # Updates elements with new values
            computing.prop 'waiting', false
            console.log "Updates other items"

  $(document).on 'keyup', '*[data-variable-handler]', ->
    $.procedures.refresh($(this))

  $('*[data-variable-actor]').each (index) ->
    $(this).on 'change', ->
      $.procedures.refresh($(this))

  true
) jQuery
