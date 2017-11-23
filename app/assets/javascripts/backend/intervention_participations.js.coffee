((E, $) ->
  'use strict'

  $(document).on 'shown.bs.modal', '#working_times', (event) ->
    participations = $(event.target).find('.participations .participation')

    if participations.length > 0
      element = $(event.target).find('.participations .participation').first()

      E.interventionParticipations.changeWorkingPeriod(element)


  $(document).on 'click', '#working_times .clear-period', (event) ->
    element = $(event.target)
    participation = element.closest('.participation')

    if !participation.next().hasClass('participation')
      participation.next().remove()

    nextParticipation = E.interventionParticipations.nextParticipation(element)
    participation.remove()

    E.interventionParticipations.changeWorkingPeriod(nextParticipation)


  $(document).on "click", "#working_times .actions .action", (event) ->
    event.preventDefault()

    element = $(this)
    button_text = element.text().trim()
    period_nature = element.attr('data-nature-period')

    participationIndex = 0
    participationsCount = $('.participations .participation').length
    workingPeriodsAttributes = "intervention_participation[working_periods_attributes][" + participationsCount + "]"

    newLine = $('<div class="participation"></div>')

    $(newLine).append('<input type="hidden" value="' + period_nature + '" name="working_period_nature" data-is-nature-hidden-field="true"></input>')
    $(newLine).append('<input type="hidden" name="working_period_started_at" data-is-hours-hidden-field="true"></input>')
    $(newLine).append('<input type="hidden" name="working_period_stopped_at" data-is-minutes-hidden-field="true"></input>')

    participation_icon = $('<div class="participation-icon"></div>')
    $(participation_icon).append('<div class="picto picto-timelapse"></div>')
    $(participation_icon).append(button_text)
    $(newLine).append(participation_icon)

    $(newLine).append('<div class="participation-form"></div>')

    hour_field = $('<div class="participation-field"></div>')
    $(hour_field).append('<input type="text" name="working_period_hours" class="participation-input" data-is-hours-field="true"></input>')
    $(hour_field).append('<span class="participation-field-label">H</span>')
    $(newLine).find('.participation-form').append(hour_field)

    min_field = $('<div class="participation-field"></div>')
    $(min_field).append('<input type="text" name="working_period_minutes" class="participation-input" data-is-minutes-field="true"></input>')
    $(min_field).append('<span class="participation-field-label">Min</span>')
    $(newLine).find('.participation-form').append(min_field)

    classes = ""
    if $('#intervention_tool').val() == "true"
      classes = "hidden"

    participationResult = $('<div class="participation-result"></div>')
    results = $('<div class="results ' + classes + '"></div>')
    $(results).append('<span class="previous-working-date"></span>')
    $(results).append('<span> &#8594; </span>')
    $(results).append('<span class="next-working-date"></span>')
    $(participationResult).append(results)
    $(newLine).append(participationResult)

    clearPeriod = $('<div class="clear-period"></div>')
    $(clearPeriod).append('<i class="picto picto-clear"></i>')
    $(newLine).append(clearPeriod)

    $('#working_times .participations').append(newLine)

    return


  $(document).on 'click', '#validParticipationsForm', (event) ->
    element = $(event.target)

    participation = new Object()
    participation.id = $('#intervention_participation_id').val()
    participation.intervention_id = $('#intervention_participation_intervention_id').val()
    participation.product_id = $('#intervention_participation_product_id').val()
    participation.state = "done"

    workingPeriods = []
    participations = $('.participation')
    has_one_full_participation = false

    $('.participation').each ->
      workingPeriodNature = $(this).find('input[name="working_period_nature"]').val()

      if workingPeriodNature != "pause"
        workingPeriod = new Object()
        workingPeriod.id= $(this).find('input[name="working_period_id"]').val()
        workingPeriod.nature = workingPeriodNature
        workingPeriod.started_at = $(this).find('input[name="working_period_started_at"]').val()
        workingPeriod.stopped_at = $(this).find('input[name="working_period_stopped_at"]').val()

        if workingPeriod.started_at != "" && workingPeriod.stopped_at != ""
          has_one_full_participation = true

        workingPeriods.push(workingPeriod)

    participation.working_periods_attributes = workingPeriods
    jsonParticipation = JSON.stringify(participation)

    concernedProductField = $('.nested-fields .selector .selector-value[value="' + participation.product_id + '"]')
    participationsCount = $('input[type="hidden"].intervention-participation').length
    existingParticipation = $('.intervention-participation[data-product-id="' + participation.product_id + '"]')

    if existingParticipation.length > 0
      existingParticipation.val(jsonParticipation)
    else
      $(concernedProductField).closest('.nested-fields').append('<input type="hidden" class="intervention-participation" name="intervention[participations_attributes][' + participationsCount + ']" value=\'' + jsonParticipation + '\' data-product-id="' + participation.product_id  + '"></input>')


    nestedFieldBlock = concernedProductField.closest('.nested-fields')
    productFieldPicto = nestedFieldBlock.find('.picto-timer-off')

    if has_one_full_participation && productFieldPicto.length == 1
      productFieldPicto.removeClass('picto-timer-off')
      productFieldPicto.addClass('picto-timer')

    @workingTimesModal = new ekylibre.modal('#working_times')
    @workingTimesModal.getModal().modal 'hide'

    E.interventionForm.displayCost(element)


  $(document).on "keyup", '#working_times .participations input[type="text"]', (event) ->
    element = $(event.target)

    if $('#working_times #intervention_tool').length == 1
      E.interventionParticipations.changeCalculMode(false)

    E.interventionParticipations.changeWorkingPeriod(element)


  $(document).on "click", '#participation_auto_calculate_equipments', (event) ->

    isChecked = $(event.target).is(':checked')
    E.interventionParticipations.changeCalculMode(isChecked)


  E.interventionParticipations =
    changeCalculMode: (value) ->
      $('#intervention_auto_calculate_working_periods').val(value)


    changeWorkingPeriod: (element) ->
      date_format = I18n.ext.datetimeFormat.fullJsFormat()
      participationsCount = $('.participations .participation').length
      participation = null

      if element.hasClass('participation')
        participation = element
      else
        participation = element.closest(".participation")


      hours = participation.find("input[data-is-hours-field='true']").val()
      minutes = participation.find("input[data-is-minutes-field='true']").val()

      previousStartedAt = null
      newDate = null

      if this.firstParticipation(participation)
        previousStartedAt = new Date($('#intervention_started_at').val())
        newDate = this.calculNewDate(previousStartedAt.getTime(), hours, minutes)
      else
        previousParticipation = this.previousParticipation(element)
        stringDate = previousParticipation.find('.next-working-date').text()

        previousStartedAt = moment(stringDate, date_format)._d

        newDate = this.calculNewDate(previousStartedAt, hours, minutes)


      formattedPreviousStartDate = moment(previousStartedAt).format(date_format)
      formattedStoppedDate = moment(newDate).format(date_format)

      participation.find('.previous-working-date').text(formattedPreviousStartDate)
      participation.find('.next-working-date').text(formattedStoppedDate)

      participation.find('input[data-is-hours-hidden-field="true"]').val(formattedPreviousStartDate)
      participation.find('input[data-is-minutes-hidden-field="true"]').val(formattedStoppedDate)


      if !this.lastParticipation(element)
        nextParticipation = this.nextParticipation(element)
        this.changeWorkingPeriod(nextParticipation)


    calculNewDate: (startDate , hours, minutes) ->
      newDate = moment(startDate)
      newDate.add(hours, 'hours')
      newDate.add(minutes, 'minutes')

    previousParticipation: (element) ->
      participation = element.closest('.participation')
      previousElement = participation.prev()

      if previousElement.hasClass('participation')
        return previousElement
      else
        previousElement.prev()

    nextParticipation: (element) ->
      participation = element.closest('.participation')
      nextElement = participation.next()

      if nextElement.hasClass('participation')
        return nextElement
      else
        nextElement.next()

    firstParticipation: (element) ->
      element.prev().hasClass('participations-header')

    lastParticipation: (element) ->
      this.nextParticipation(element).length == 0


  true
) ekylibre, jQuery
