((E, $) ->
  'use strict'

  $(document).on "click", "#working_times .actions .action", (event) ->
    event.preventDefault()

    element = $(this)
    button_text = element.text().trim()
   
    participationIndex = 0
    participationsCount = $('.participations .participation').length - 1

    if (participationsCount > 0)
      participationIndex = participationsCount - 1

    workingPeriodsAttributes = "intervention_participation[working_periods_attributes][" + participationIndex + "]"

    new_line = $('<div class="participation"></div>')

    participation_icon = $('<div class="participation-icon"></div>')
    $(participation_icon).append('<div class="picto picto-timelapse"></div>')
    $(participation_icon).append(button_text)
    $(new_line).append(participation_icon)

    $(new_line).append('<div class="participation-form"></div>')

    hour_field = $('<div class="participation-field"></div>')
    $(hour_field).append('<input type="text" name="' + workingPeriodsAttributes + '[hours]" class="participation-input" data-is-hours-field="true"></input>')
    $(hour_field).append('<span class="participation-field-label">H</span>')
    $(new_line).find('.participation-form').append(hour_field)

    min_field = $('<div class="participation-field"></div>')
    $(min_field).append('<input type="text" name="' + workingPeriodsAttributes + '[minutes]" class="participation-input" data-is-minutes-field="true"></input>')
    $(min_field).append('<span class="participation-field-label">Min</span>')
    $(new_line).find('.participation-form').append(min_field)

    participationResult = $('<div class="participation-result"></div>')
    $(participationResult).append('<span class="previous-working-date"></span>')
    $(participationResult).append('<span> &#8594; </span>')
    $(participationResult).append('<span class="next-working-date"></span>')
    $(new_line).append(participationResult)

    $('#working_times .participations').append(new_line)

    return

  $(document).on "submit", '.edit_intervention_participation input[type="submit"]', (event) ->
    event.preventDefault()

    $('.edit_intervention_participation').submit()

    @workingTimesModal = new ekylibre.modal('#working_times')
    @workingTimesModal.getModal().modal 'hide'


  $(document).on "change", '#working_times .participations input[type="text"]', (event) ->
    element = $(event.target)
    form = $(element).closest('.participation-form')
    participationsCount = $('.participations .participation').length
    
    participations = $(element).closest('.participations')
    participation = element.closest(".participation")
    date_format = I18n.ext.datetimeFormat.fullJsFormat()

    hours = form.find("input[data-is-hours-field='true']").val()
    minutes = form.find("input[data-is-minutes-field='true']").val()

    previousStartedAt = null
    newDate = null

    if participationsCount == 1
      previousStartedAt = new Date($('#intervention_started_at').val())
      newDate = E.interventionParticipations.calculNewDate(previousStartedAt.getTime(), hours, minutes)
    else
      previousParticipation = E.interventionParticipations.previousParticipation(element)
      stringDate = previousParticipation.find('.next-working-date').text()

      previousStartedAt = moment(stringDate, date_format)._d

      newDate = E.interventionParticipations.calculNewDate(previousStartedAt, hours, minutes)

    participation.find('.previous-working-date').text(moment(previousStartedAt).format(date_format))
    participation.find('.next-working-date').text(moment(newDate).format(date_format))


  E.interventionParticipations =
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

  true
) ekylibre, jQuery
