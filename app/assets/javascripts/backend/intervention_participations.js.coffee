((E, $) ->
  'use strict'

  $(document).on "click", "#working_times .actions .action", (event) ->
    event.preventDefault()

    element = $(this)
    button_text = element.text().trim()

    new_line = $('<div class="participation"></div>')

    participation_icon = $('<div class="participation-icon"></div>')
    $(participation_icon).append('<div class="picto picto-timelapse"></div>')
    $(participation_icon).append(button_text)
    $(new_line).append(participation_icon)

    $(new_line).append('<div class="participation-form"></div>')

    hour_field = $('<div class="participation-field"></div>')
    $(hour_field).append('<input type="text" name="name" class="participation-input"></input>')
    $(hour_field).append('<span class="participation-field-label">H</span>')
    $(new_line).find('.participation-form').append(hour_field)

    min_field = $('<div class="participation-field"></div>')
    $(min_field).append('<input type="text" name="name" class="participation-input"></input>')
    $(min_field).append('<span class="participation-field-label">Min</span>')
    $(new_line).find('.participation-form').append(min_field)

    $(new_line).append('<div class="participation-result"></div>')

    $('#working_times .participations').append(new_line)

    return

  $(document).on "submit", '.edit_intervention_participation input[type="submit"]', (event) ->
    event.preventDefault()

    $('.edit_intervention_participation').submit()

    @workingTimesModal = new ekylibre.modal('#working_times')
    @workingTimesModal.getModal().modal 'hide'


  # $(document).on "change", '.edit_intervention_participation input[type="text"]', (event) ->
  #   element = $(event.target)
  #   parent = $(element).closest('.participation-field')
  #   label = $(parent).find(".participation-field-label").val()

  
  # add hours
  # new Date((new Date($('#intervention_started_at').val()).getTime() + (1*60*60*1000)))
  #
  # add minutes
  # (30 * 60 * 1000)

  true
) ekylibre, jQuery
