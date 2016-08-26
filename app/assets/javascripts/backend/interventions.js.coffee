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

    handleComponents: (form, attributes, prefix = '') ->
      for name, value of attributes
        subprefix = prefix + name
        if /\w+_attributes$/.test(name)
          for id, attrs of value
            E.interventions.handleComponents(form, attrs, subprefix + '_' + id + '_')
        else
          input = form.find("##{prefix}component_id")
          unrollPath = input.attr('data-selector')
          if unrollPath
            assemId = attributes["assembly_id"]
            if typeof(assemId) == 'undefined' or assemId is null
              assemId = "nil"
            componentReg = /(unroll\?.*scope.*components_of_product[^=]*)=([^&]*)(&?.*)/
            oldAssembly = unrollPath.match(componentReg)[2]
            unrollPath = unrollPath.replace(componentReg, "$1="+assemId+"$3")
            input.attr('data-selector', unrollPath)
            if assemId.toString() != oldAssembly.toString()
              console.log "CLEAR"
              $(input).val('')


    toggleHandlers: (form, attributes, prefix = '') ->
      for name, value of attributes
        subprefix = prefix + name
        if /\w+_attributes$/.test(name)
          for id, attrs of value
            E.interventions.toggleHandlers(form, attrs, subprefix + '_' + id + '_')
        else
          select = form.find("##{prefix}quantity_handler")
          console.warn "Cannot find ##{prefix}quantity_handler <select>" unless select.length > 0
          option = select.find("option[value='#{name}']")
          console.warn "Cannot find option #{name} of ##{prefix}quantity_handler <select>" unless option.length > 0
          if value && !option.is(':visible')
            option.show()
          else if !value && option.is(':visible')
            option.hide()

    unserializeRecord: (form, attributes, prefix = '', updater_id = null) ->
      for name, value of attributes
        subprefix = prefix + name
        if subprefix is updater_id
          # Nothing to update
          # console.warn "Nothing to do with #{subprefix}"
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
              if (value.geometries? and value.geometries.length > 0) || (value.coordinates? and value.coordinates.length > 0)
                element.mapeditor "edit", value
                try
                  element.mapeditor "view", "edit"
            else if element.is('select')
              element.find("option[value='#{value}']")[0].selected = true
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

    updateAvailabilityInstant: (newTime) ->
      return unless newTime != ''
      $("input.scoped-parameter").each (index, item) ->
        scopeUri = decodeURI($(item).data("selector"))
        re =  /(scope\[availables\]\[\]\[at\]=)(.*)(&)/
        scopeUri = scopeUri.replace(re, "$1" + newTime + "$3")
        $(item).attr("data-selector", encodeURI(scopeUri))

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
      if computing.prop('state') isnt 'waiting'
        $.ajax
          url: computing.data('procedure')
          type: "PATCH"
          data: form.serialize()
          beforeSend: ->
            computing.prop 'state', 'waiting'
          error: (request, status, error) ->
            computing.prop 'state', 'ready'
            false
          success: (data, status, request) ->
            console.group('Unserialize intervention updated by ' + updaterId)
            # Updates elements with new values
            E.interventions.toggleHandlers(form, data.handlers, 'intervention_')
            E.interventions.handleComponents(form, data.intervention, 'intervention_', data.updater_id)
            E.interventions.unserializeRecord(form, data.intervention, 'intervention_', data.updater_id)
            # if updaterElement? and initialValue != E.value($("*[data-intervention-updater='#{intervention.updater}']").first())
            #   E.interventions.refresh updaterElement
            computing.prop 'state', 'ready'
            console.groupEnd()


  ##############################################################################
  # Triggers
  #
  $(document).on 'cocoon:after-insert', (e, i) ->
    $('input[data-map-editor]').each ->
      $(this).mapeditor()
    $(".nested-fields.working-period:first-child input.intervention-started-at").each ->
      $(this).each ->
        E.interventions.updateAvailabilityInstant($(this).val())
    $('*[data-intervention-updater]').each ->
        E.interventions.refresh $(this)

  $(document).on 'mapchange', '*[data-intervention-updater]', ->
    $(this).each ->
      E.interventions.refresh $(this)

  #  selector:initialized
  $(document).on 'selector:change', '*[data-intervention-updater]', ->
    $(this).each ->
      E.interventions.refresh $(this)

  $(document).on 'keyup', 'input[data-selector]', (e) ->
    $(this).each ->
      E.interventions.refresh $(this)

  $(document).on 'keyup change', 'input[data-intervention-updater]:not([data-selector])', (e) ->
    $(this).each ->
      E.interventions.refresh $(this)

  $(document).on 'keyup change', 'select[data-intervention-updater]', ->
    $(this).each ->
      E.interventions.refresh $(this)

  $(document).on "keyup change", ".nested-fields.working-period:first-child input.intervention-started-at", ->
    $(this).each ->
      E.interventions.updateAvailabilityInstant($(this).val())

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
