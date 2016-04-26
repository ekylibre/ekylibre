# This module permits to execute an procedure to generate operations
# with the user interaction.

((E, $) ->
  'use strict'

  E.value = (element) ->
    if element.is(":ui-selector")
      return element.selector("value")
    else
      return element.val()

  # Interventions permit to enhances data input through context computation
  # The concept is: When an update is done, we ask server which are the impact on
  # other fields and on updater itself if necessary
  E.interventions =

    unserializeRecord: (form, attributes, prefix = '', updater_id = null) ->
      for name, value of attributes
        subprefix = prefix + name
        console.log "Test if '#{updater_id}' == '#{subprefix}'"
        if subprefix is updater_id
          # Nothing to update
          console.warn "Nothing to do with #{subprefix}"
        else if /\w+_attributes$/.test(name)
          E.interventions.unserializeList(form, value, subprefix + '_', updater_id)
        else
          form.find("##{subprefix}").each (index) ->
            element = $(this)
            if element.is(':ui-selector')
              if value != element.selector('value')
                if value is null
                  console.log "Clear ##{subprefix}"
                  element.selector('clear')
                else
                  console.log "Updates ##{subprefix} with: ", value
                  element.selector('value', value)
            else if element.is(":ui-mapeditor")
              value = $.parseJSON(value)
              element.mapeditor "show", value
              element.mapeditor "edit", value
              try
                element.mapeditor "view", "edit"
            else
              valueType = typeof value
              update = true
              update = false if value is null and element.val() is ""
              if valueType == "number"
                update = false if value == element.numericalValue()
              else
                update = false if value == element.val()
              if update
                console.log "Updates ##{subprefix} with: ", value
                element.val(value)

    unserializeList: (form, list, prefix = '', updater_id) ->
      for id, attributes of list
        E.interventions.unserializeRecord(form, attributes, prefix + id + '_', updater_id)

    # Ask for a refresh of values depending on given field
    refresh: (origin) ->
      this.refreshHard(origin)
      # this.refreshHardz(origin.data('procedure'), origin.data('intervention-updater'), origin)

    # Ask for a refresh of values depending on given update
    refreshHard: (updater) ->
      unless updater?
        console.error 'Missing updater'
        return false
      updaterId = updater.data('intervention-updater')
      unless updaterId?
        console.warn 'No updater id, so no refresh'
        return false
      form = updater.closest('form')
      form.find("input[name='updater']").val(updaterId)
      computing = form.find('*[data-procedure]').first()
      unless computing.length > 0
        console.error 'Cannot procedure element where compute URL is defined'
        return false
      console.log 'in refreshing'
      if computing.prop('state') isnt 'waiting'
        console.log 'in ajax'
        $.ajax
          url: computing.data('procedure')
          type: "PATCH"
          data: form.serialize()
          beforeSend: ->
            console.log 'waiting'
            computing.prop 'state', 'waiting'
          error: (request, status, error) ->
            computing.prop 'state', 'ready'
            false
          success: (data, status, request) ->
            console.group('Unserialize intervention updated by ' + updaterId)
            console.log(data)
            # Updates elements with new values
            E.interventions.unserializeRecord(form, data.intervention, 'intervention_', data.updater_id)
            # if updaterElement? and initialValue != E.value($("*[data-intervention-updater='#{intervention.updater}']").first())
            #   E.interventions.refresh updaterElement
            computing.prop 'state', 'ready'
            console.groupEnd()
          complete: () ->
            console.log 'ready'


  ##############################################################################
  # Triggers
  #
  $(document).on 'cocoon:after-insert', ->
    $('input[data-map-editor]').each ->
      $(this).mapeditor()

  $(document).on 'mapchange', '*[data-intervention-updater]', ->
    $(this).each ->
      E.interventions.refresh $(this)

  #  selector:initialized
  $(document).on 'selector:change', '*[data-intervention-updater]', ->
    $(this).each ->
      E.interventions.refresh $(this)

  $(document).on 'keyup', 'input[data-intervention-updater]', ->
    $(this).each ->
      E.interventions.refresh $(this)

  # $(document).on 'change', '*[data-procedure-global="at"]', ->
  #   $(this).each ->
  #     E.interventions.refresh $(this)

  # $(document).behave 'load', '*[data-procedure]', (event) ->
  #   $(this).each ->
  #     E.interventions.refresh $(this)

  # # Filters supports with given production
  # # Hides supports line if needed
  # $(document).behave "load selector:set", "*[data-intervention-updater='global:production']", (event) ->
  #   production = $(this)
  #   id = production.selector('value')
  #   form = production.closest('form')
  #   url = "/backend/production_supports/unroll?scope[of_current_campaigns]=true"
  #   support = form.find("*[data-intervention-updater='global:support']").first()
  #   if /^\d+$/.test(id)
  #     url += "&scope[of_productions]=#{id}"
  #     form.addClass("with-supports")
  #   else
  #     form.removeClass("with-supports")
  #   support.attr("data-selector", url)
  #   support.data("selector", url)

  true
) ekylibre, jQuery
