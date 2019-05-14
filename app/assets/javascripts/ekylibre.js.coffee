((E, $) ->
  "use strict"

  #
  # AJAX error handler
  E.ajaxErrorHandler = (request, status, error) ->
    if console.error?
      console.error "AJAX failure (#{status}): #{error}"
    else
      alert("AJAX failure (#{status}): #{error}")
      console.log "AJAX failure (#{status}): #{error}"
    return true

  # This util method is used to simulate both
  # event.preventDefault() and event.stopPropagation().
  # It is used for compatibility issues as IE8 and below do
  # not handle event.preventDefault() or event.stopPropagation().
  E.stopEvent = (event) ->
    if !event
      event = window.event

    if !event
      return;

    if event.stopped == 'undefined' || event.stopped == undefined

      event.cancelBubble = true
      event.returnValue = false

      if event.stopPropagation
        event.stopPropagation()

      if event.stopImmediatePropagation
        event.stopImmediatePropagation()

      if event.preventDefault
        event.preventDefault()


  E.toggleValidateButton = (container) ->
    requiredFields = container.find('input[data-required]')
    validateItemButton = container.find('button[data-validate]')
    toggleState = ->
      requiredFields.not(':hidden').each ->
        if $(this).val() == ''
          validateItemButton.attr("disabled", true)
          return false
        else
          validateItemButton.attr("disabled", null)
    toggleState()
    requiredFields.each ->
      element = $(this)
      element.on "selector:change", toggleState
      element.change toggleState
    container.bind 'visibility:change', toggleState

  E.setStorageUnitName = (container) ->
    container.find('.storing-fields:visible').last().find('.storage-unit-name').html(container.find('.storing-fields').first().find('.storage-unit-name').first().text())


) ekylibre, jQuery
