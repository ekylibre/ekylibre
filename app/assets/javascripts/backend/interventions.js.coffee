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
            assemblyId = attributes["assembly_id"]
            if typeof(assemblyId) == 'undefined' or assemblyId is null
              assemblyId = "nil"
            componentReg = /(unroll\?.*scope.*components_of_product[^=]*)=([^&]*)(&?.*)/
            oldAssemblyId = unrollPath.match(componentReg)[2]
            unrollPath = unrollPath.replace(componentReg, "$1=#{assemblyId}$3")
            input.attr('data-selector', unrollPath)
            if assemblyId.toString() != oldAssemblyId.toString()
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
          if value
            option.show()
          else
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
                # When element doesn't have any value, element.numericalValue() == 0
                update = false if value == element.numericalValue() && element.numericalValue() != 0
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

    # Ask for a refresh of values depending on given update
    refresh: (updater, options = {}) ->
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
            computing.prop 'state', 'ready'
            options.success.call(this, data, status, request) if options.success?
            console.groupEnd()


  ##############################################################################
  # Triggers
  #
  $(document).on 'cocoon:after-insert', (e, i) ->
    $('input[data-map-editor]').each ->
      $(this).mapeditor()
    $('#parameters *[data-intervention-updater]').each ->
      E.interventions.refresh $(this),
        success: (stat, status, request) ->
          E.interventions.updateAvailabilityInstant($(".nested-fields.working-period:first-child input.intervention-started-at").first().val())

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

  $(document).ready ->

    if $('.taskboard').length > 0

      taskboard = new InterventionsTaskboard
      taskboard.initTaskboard()


  class InterventionsTaskboard

    constructor: ->
      @taskboard = new ekylibre.taskboard('#interventions', true)
      @taskboardModal = new ekylibre.modal('#taskboard-modal')

    initTaskboard: ->
      this.addHeaderActionsEvent()
      this.addEditIconClickEvent()
      this.addDeleteIconClickEvent()
      this.addTaskClickEvent()

    getTaskboard: ->
      return @taskboard

    getTaskboardModal: ->
      return @taskboardModal

    addHeaderActionsEvent: ->

      instance = this

      @taskboard.addSelectTaskEvent((event) ->

          selectedField = $(event.target)
          columnIndex = instance.getTaskboard().getColumnIndex(selectedField)
          header = instance.getTaskboard().getHeaderByIndex(columnIndex)
          checkedFieldsCount = instance.getTaskboard().getCheckedSelectFieldsCount(selectedField)

          if (checkedFieldsCount == 0)

            instance.getTaskboard().hiddenHeaderIcons(header)
          else
            instance.getTaskboard().displayHeaderIcons(header)
      )

    addEditIconClickEvent: ->

      instance = this

      @taskboard.getHeaderActions().find('.edit-tasks').on('click', (event) ->

        interventionsIds = instance._getSelectedInterventionsIds(event.target)

        $.ajax
          url: "/backend/interventions/modal",
          data: {interventions_ids: interventionsIds}
          success: (data, status, request) ->

            instance._displayModalWithContent(data)
      )


    addDeleteIconClickEvent: ->

      instance = this

      $(document).on('confirm:complete', (event, answer) ->

        if ($(event.target).find('.delete-tasks').length == 0 || !answer)
          return


        columnSelector = event.target
        interventionsIds = instance._getSelectedInterventionsIds(columnSelector)

        $.ajax
          method: 'POST'
          url: "/backend/interventions/change_state",
          data: {
            'intervention': {
              interventions_ids: JSON.stringify(interventionsIds),
              state: 'rejected'
            }
          }
          success: (data, status, request) ->

            selectedTasks = instance.getTaskboard().getSelectedTasksByColumnSelector(columnSelector)
            selectedTasks.remove()

      )


    _getSelectedInterventionsIds: (columnSelector) ->

      selectedTasks = @taskboard.getSelectedTasksByColumnSelector(columnSelector)

      interventionsIds = [];
      selectedTasks.each( ->

        interventionDatas = JSON.parse($(this).attr('data-intervention'))
        interventionsIds.push(interventionDatas.id);
      );

      return interventionsIds


    addTaskClickEvent: ->

      instance = this

      @taskboard.addTaskClickEvent((event) ->

        element = $(event.target)

        if (element.is(':input[type="checkbox"]'))
          return

        task = element.closest('.task')

        intervention = JSON.parse(task.attr('data-intervention'))

        $.ajax
          url: "/backend/interventions/modal",
          data: {intervention_id: intervention.id}
          success: (data, status, request) ->

            instance._displayModalWithContent(data)
            instance.getTaskboardModal().getModal().find('.dropup a').on('click', (event) ->

              dropdown = $(this).closest('.dropup')
              dropdown.removeClass('open')

              dropdownButton = dropdown.find('.dropdown-toggle')
              dropdownButton.text(dropdownButton.attr('data-disable-with'))
              dropdownButton.attr('disabled', 'disabled')
            )
      )


    _displayModalWithContent: (data) ->

      @taskboardModal.removeModalContent()
      @taskboardModal.getModalContent().append(data)
      @taskboardModal.getModal().modal 'show'

  true
) ekylibre, jQuery
