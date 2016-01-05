# This module permits to execute an procedure to generate operations
# with the user interaction.

((E, $) ->
  'use strict'

  $.value = (element) ->
    if element.is(":ui-selector")
      return element.selector("value")
    else
      return element.val()

  # Interventions permit to enhances data input through context computation
  # The concept is: When an update is done, we ask server which are the impact on
  # other fields and on updater itself if necessary
  $.interventions =

    computeUniqueId: (element) ->
      if element.attr('data-object-uid')?
        return element.attr('data-object-uid')
      if element.data('intervention-field')?
        uid = element.data('intervention-field')
      else if element.data('intervention-parameter')?
        parameter_name = element.data('intervention-parameter')
        index = element.closest('form').find("*[data-intervention-parameter='#{parameter_name}']").index(element)
        uid = "#{parameter_name}:#{index}"
      else
        console.error 'Cannot find id for:', element
        return
      parameter = element.parent().closest('*[data-intervention-parameter]')
      if parameter.length > 0
        uid = "#{$.interventions.computeUniqueId(parameter.first())}:#{uid}"
      element.attr('data-object-uid', uid)
      return uid

    # Serialize global data with data-procedure-global attribute
    serializeGlobal: (procedure) ->
      global = {}
      $("*[data-procedure='#{procedure}'][data-procedure-global]").each ->
        global[$(this).data('procedure-global')] = $.value $(this)
      global

    serializeCasting: (procedure) ->
      casting = {}
      $("*[data-procedure='#{procedure}'][data-variable-handler]").each (index) ->
        variable = $(this).data('variable')
        casting[variable] ?= {}
        casting[variable].handlers ?= {}
        casting[variable].handlers[$(this).data('variable-handler')] =
          value: $.value($(this))

      $("*[data-procedure='#{procedure}'][data-variable-destination]").each (index) ->
        variable = $(this).data('variable')
        casting[variable] ?= {}
        casting[variable].destinations ?= {}
        casting[variable].destinations[$(this).data('variable-destination')] = $.value $(this)

      $("*[data-procedure='#{procedure}'][data-variable-actor]").each (index) ->
        variable = $(this).data('variable')
        casting[variable] ?= {}
        casting[variable].actor = $.value $(this)

      $("*[data-procedure='#{procedure}'][data-variable-variant]").each (index) ->
        variable = $(this).data('variable')
        casting[variable] ?= {}
        casting[variable].variant = $.value $(this)

      casting

    unserialize: (procedure, data, updater) ->
      casting = data.casting
      if data.stopped_at
        $("*[data-procedure='#{procedure}'][data-procedure-global='stopped_at']").each (index) ->
          element = $(this)
          element.val(data.stopped_at)
      if data.started_at
        $("*[data-procedure='#{procedure}'][data-procedure-global='at']").each (index) ->
          element = $(this)
          element.val(data.started_at)

      # console.log("Unserialize data")
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
                element.selector("value", attributes.variant)
            else if attributes.variant != parseInt element.val()
              element.val(attributes.variant)

        if attributes.handlers?
          for handler, attrs of attributes.handlers
            value = attrs.value
            $("*[data-procedure='#{procedure}'][data-variable='#{variable}'][data-variable-handler='#{handler}']").each (index) ->
              element = $(this)
              if attrs.usable
                element.closest(".handler").show()
              else
                element.closest(".handler").hide()
              if element.is(":ui-mapeditor")
                element.mapeditor "show", value
                element.mapeditor "edit", value
                try
                  element.mapeditor "view", "edit"
              else if value != parseFloat element.val()
                unless updater == element.data('intervention-updater')
                  element.val(value)

        if attributes.destinations?
          for destination, value of attributes.destinations
            $("*[data-procedure='#{procedure}'][data-variable='#{variable}'][data-variable-destination='#{destination}']").each (index) ->
              # TODO: Find a better way later to manage different datatypes like geometry
              if destination is 'shape'
                $(this).val(JSON.stringify(value))
              else
                $(this).val(value)

    # Ask for a refresh of values depending on given field
    refresh: (origin) ->
      this.refreshHard(origin)
      # this.refreshHardz(origin.data('procedure'), origin.data('intervention-updater'), origin)

    # Ask for a refresh of values depending on given update
    refreshHard: (updater) ->
      unless updater?
        console.error 'Missing updater'
        return false
      $.interventions.computeUniqueId(updater)
      console.log updater.data('intervention-updater')
      form = updater.closest('form')
      computing = form.find('*[data-procedure]')
      unless computing.length > 0
        console.error 'Cannot procedure element where compute URL is defined'
        return false
      computing = computing.first()
      # console.log updaterElement.closest('form')
      if computing.prop('state') isnt 'waiting'
        $.ajax
          url: computing.data('procedure')
          data: form.serialize()
          beforeSend: ->
            computing.prop 'state', 'waiting'
          error: (request, status, error) ->
            computing.prop 'state', 'ready'
            false
          success: (data, status, request) ->
            computing.prop 'state', 'ready'
            console.log 'Update data'
            # Updates elements with new values
            # $.interventions.unserialize(procedure, data, intervention.updater)
            # if updaterElement? and initialValue != $.value($("*[data-intervention-updater='#{intervention.updater}']").first())
            #   $.interventions.refresh updaterElement

    refreshHardz: (procedure, updaterName = 'initial', updaterElement = null) ->
      computing = $("*[data-procedure-computing='#{procedure}']")
      unless computing.length > 0
        console.log "No computing element for #{procedure}"
        console.log computing
      computing = computing.first()
      if computing.prop('state') isnt 'waiting'
        # Serialize data
        intervention =
          procedure: procedure
          updater: updaterName
          global:  $.interventions.serializeGlobal(procedure)
          casting: $.interventions.serializeCasting(procedure)

        # Ask server for reverberated updates
        initialValue = $.value($("*[data-intervention-updater='#{intervention.updater}']").first())
        $.ajax
          url: computing.val()
          data: intervention
          beforeSend: ->
            computing.prop 'state', 'waiting'
          error: (request, status, error) ->
            computing.prop 'state', 'ready'
            false
          success: (data, status, request) ->
            computing.prop 'state', 'ready'
            # Updates elements with new values
            $.interventions.unserialize(procedure, data, intervention.updater)
            if updaterElement? and initialValue != $.value($("*[data-intervention-updater='#{intervention.updater}']").first())
              $.interventions.refresh updaterElement

  ##############################################################################
  # Triggers
  $(document).on 'keyup mapchange', '*[data-variable-handler]', ->
    $(this).each ->
      $.interventions.refresh $(this)

  $(document).on 'selector:change selector:initialized', '*[data-intervention-updater]', ->
    $(this).each ->
      $.interventions.refresh $(this)

  $(document).on 'keyup change', 'select[data-intervention-updater], input[data-intervention-updater]', ->
    $(this).each ->
      $.interventions.refresh $(this)

  $(document).on 'change', '*[data-procedure-global="at"]', ->
    $(this).each ->
      $.interventions.refresh $(this)

  $(document).behave 'load', '*[data-procedure]', (event) ->
    $(this).each ->
      $.interventions.refresh $(this)

  # Filters supports with given production
  # Hides supports line if needed
  $(document).behave "load selector:set", "*[data-intervention-updater='global:production']", (event) ->
    production = $(this)
    id = production.selector('value')
    form = production.closest('form')
    url = "/backend/production_supports/unroll?scope[of_current_campaigns]=true"
    support = form.find("*[data-intervention-updater='global:support']").first()
    if /^\d+$/.test(id)
      url += "&scope[of_productions]=#{id}"
      form.addClass("with-supports")
    else
      form.removeClass("with-supports")
    support.attr("data-selector", url)
    support.data("selector", url)

  true
) ekylibre, jQuery
