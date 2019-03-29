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
    updateProcedureLevelAttributes: (form, attributes) ->
      for name, properties of attributes
        parameterContainer = $("[data-intervention-parameter='#{name}']").parent('.nested-association')
        if properties.display
          statusDisplay = parameterContainer.find(".display-info")
          statusDisplay.find(" .status")
                       .attr('data-display-status', properties.display)
          statusDisplay.show()

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


    handleDynascope: (form, attributes, prefix = '') ->
      for name, value of attributes
        subprefix = prefix + name
        if /\w+_attributes$/.test(name)
          for id, attrs of value
            E.interventions.handleDynascope(form, attrs, subprefix + '_' + id + '_')
        else
          if name is 'attributes' and value?
            # for each attribute
            for k, v of value
              input = form.find("##{prefix}#{k}")
              unrollPath = input.attr('data-selector')
              if unrollPath
                # for each scope
                for scopeKey, scopeValue of v.dynascope

                  scopeReg = ///
                  (.* #root
                  unroll\\?.*scope.*#{scopeKey}[^=]*) # current scope
                  = ([^&]*) # current value to change
                  (&?.*)
                  ///
                  unrollPath = unrollPath.replace(scopeReg, "$1=#{encodeURIComponent(scopeValue)}$3")

                input.attr('data-selector', unrollPath)

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
#          console.log subprefix
          form.find("##{subprefix}").each (index) ->
            if 'errors' in Object.keys(attributes)
              $(this).parent('.nested-fields').find(".errors *").hide()
              for error, message of attributes.errors
                errorMessage = $(this).parent('.nested-fields').find(".errors .#{error}")
                if typeof(message) != 'undefined'
                  errorMessage.show()
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
            E.interventions.handleDynascope(form, data.intervention, 'intervention_', data.updater_id)
            E.interventions.unserializeRecord(form, data.intervention, 'intervention_', data.updater_id)
            E.interventions.updateProcedureLevelAttributes(form, data.procedure_states)
            computing.prop 'state', 'ready'
            options.success.call(this, data, status, request) if options.success?
            console.groupEnd()

    hideKujakuFilters: (hideFilters) ->
      if hideFilters
        $('.feathers input[name*="nature"], .feathers input[name*="state"]').closest('.feather').hide()
      else
        $('.feathers input[name*="nature"], .feathers input[name*="state"]').closest('.feather').show()

    showInterventionParticipationsModal: ->
      $(document).on 'click', '.has-intervention-participations', (event) ->

        targetted_element = $(event.target)
        intervention_id = $('input[name="intervention_id"]').val()
        product_id = $(event.target).closest('.nested-product-parameter').find(".selector .selector-value").val()
        existingParticipation = $('.intervention-participation[data-product-id="' + product_id + '"]').val()
        participations = $('intervention_participation')
        interventionStartedAt = $('#intervention_working_periods_attributes_0_started_at').val()

        participations = []
        $('.intervention-participation').each ->
          participations.push($(this).val())

        autoCalculMode = true
        if $('input[name="auto-calcul-mode"]').length == 0
          $('.simple_form').append('<input type="hidden" name="auto-calcul-mode" value="true"></input>')
        else
          autoCalculMode = $('input[name="auto-calcul-mode"]').val()


        datas = {}
        datas['intervention_id'] = intervention_id
        datas['product_id'] = product_id
        datas['existing_participation'] = existingParticipation
        datas['participations'] = participations
        datas['intervention_started_at'] = interventionStartedAt
        datas['auto_calcul_mode'] = autoCalculMode

        $.ajax
          url: "/backend/intervention_participations/participations_modal",
          data: datas
          success: (data, status, request) ->

            @workingTimesModal = new ekylibre.modal('#working_times')
            @workingTimesModal.removeModalContent()
            @workingTimesModal.getModalContent().append(data)
            @workingTimesModal.getModal().modal 'show'

    addLazyLoading: ->
      loadContent = false
      currentPage = 1
      taskHeight = 60
      halfTaskList = 12

      urlParams = decodeURIComponent(window.location.search.substring(1)).split("&")
      params = urlParams.reduce((map, obj) ->
        param = obj.split("=")
        map[param[0]] = param[1]
        return map
      , {})

      $('#content').scroll ->
        if !loadContent && $('#content').scrollTop() > (currentPage * halfTaskList) * taskHeight
          currentPage++
          params['page'] = currentPage

          loadContent = true

          $.ajax
            url: "/backend/interventions/change_page",
            data: { interventions_taskboard: params }
            success: (data, status, request) ->
              loadContent = false
              taskboard.addTaskClickEvent()


  ##############################################################################
  # Triggers
  #
  $(document).on 'cocoon:after-insert', (e, i) ->
    $('input[data-map-editor]').each ->
      $(this).mapeditor()
    $('#working-periods *[data-intervention-updater]').each ->
      E.interventions.refresh $(this),
        success: (stat, status, request) ->
          E.interventions.updateAvailabilityInstant($(".nested-fields.working-period:first-child input.intervention-started-at").first().val())

  $(document).on 'cocoon:after-remove', (e, i) ->
    $('#working-periods *[data-intervention-updater]').each ->
      E.interventions.refresh $(this)

  $(document).on 'mapchange', '*[data-intervention-updater]', ->
    $(this).each ->
      E.interventions.refresh $(this)

  $(document).ready ->
    $('*[data-intervention-updater]').each ->
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

  $(document).on "keyup change dp.change", ".nested-fields.working-period:first-child input.intervention-started-at", (e) ->
    $(this).each ->
      E.interventions.updateAvailabilityInstant($(this).val())


  $(document).on "selector:change", 'input[data-selector-id="intervention_doer_product_id"], input[data-selector-id="intervention_tool_product_id"]', (event) ->
    element = $(event.target)
    blockElement = element.closest('.nested-fields')

    pictoTimer = $('<div class="has-intervention-participations picto picto-timer-off"></div>')

    $(blockElement).append(pictoTimer)

    participation = blockElement.find('.intervention-participation')

    if participation.length > 0
      newProductId = element.closest('.selector').find('.selector-value').val()
      jsonParticipation = JSON.parse(participation.val())
      jsonParticipation.product_id = newProductId

      participation.val(JSON.stringify((jsonParticipation)))
      participation.attr('data-product-id', newProductId)



  $(document).ready ->

    # E.interventions.hideKujakuFilters($('.view-toolbar a[data-janus-href="cobbles"]').hasClass('active'))

    if $('.new_intervention, .edit_intervention').length > 0
      E.interventions.showInterventionParticipationsModal()

    if $('.taskboard').length > 0

      taskboard = new InterventionsTaskboard
      taskboard.initTaskboard()

      E.interventions.addLazyLoading()


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

      $('.delete-tasks').on('click', (event) ->

        ekylibre.stopEvent(event)

        confirmMessage = $(event.target).attr('data-confirm')
        answer = confirm(confirmMessage);

        if !answer
          return

        displayDeleteModal = true
        columnSelector = event.target
        interventionsIds = instance._getSelectedInterventionsIds(columnSelector)

        tasksWithAttribute = instance.getTaskboard().getColumnTasksFilledDataAttribute(columnSelector, 'data-request-intervention-id')

        if (!tasksWithAttribute || tasksWithAttribute.length == 0)
          displayDeleteModal = false
        else
          tasksWithAttribute.each((index, taskWithAttribute) ->

            attributeValue = $(taskWithAttribute).attr('data-request-intervention-id')
            tasksWithThisAttributeValue = instance.getTaskboard().getColumnTasksByDataAttributeValue(columnSelector, 'data-request-intervention-id', attributeValue)

            if (tasksWithThisAttributeValue && tasksWithThisAttributeValue.length > 1)
              displayDeleteModal = false
          )

        if (displayDeleteModal)
          $.ajax
            url: "/backend/interventions/modal",
            data: {modal_type: "delete", interventions_ids: interventionsIds}
            success: (data, status, request) ->

              instance._displayModalWithContent(data)
        else
          instance._removeInterventions(columnSelector, interventionsIds)

      )

    _removeInterventions: (columnSelector, interventionsIds) ->

      instance = this

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

          interventionsIds.forEach (intervention_id) ->
            $('#interventions-list tr[id*="'+intervention_id+'"]').remove()

          selectedTasks = instance.getTaskboard().getSelectedTasksByColumnSelector(columnSelector)
          selectedTasks.remove()

          titleElement = $(columnSelector).closest('.taskboard-header').find('.title')
          columnTitle = titleElement.text()
          beginInterventionCount = columnTitle.indexOf("(") + 1
          columnInterventionCount = columnTitle.slice(beginInterventionCount, -1)
          newInterventionCount = parseInt(columnInterventionCount) - interventionsIds.length
          newColumnTitle = columnTitle.slice(0, beginInterventionCount) + newInterventionCount+")"
          titleElement.text(newColumnTitle)

          if newInterventionCount == 0
            $(columnSelector).closest('.taskboard-column').find('.tasks').remove()


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
