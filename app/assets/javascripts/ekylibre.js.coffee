((E, $) ->
  "use strict"
  class DOMMutationObserver
    constructor: (element) ->
      @element = element
      @observer = null
      @listeners = []

    started: () -> @observer != null

    start: () ->
      @_createObserver()
      @_observe()

    addListener: (selector, callback) ->
      @listeners.push
        selector: selector
        callback: callback
      @start() unless @started()

    addListeners: (hash) ->
      for selector,callback of hash
        @addListener selector, callback

    _createObserver: () ->
      @observer = new MutationObserver (mutationList, observer) =>
        for mutation in mutationList
          for listener in @listeners
            $element = $(listener.selector, mutation.addedNodes)
            listener.callback $element if $element.length
        return

    _observe: () ->
      $ => @observer.observe(@element, {childList: true, subtree: true})

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
    requiredFields = container.find('[data-required]')
    validateItemButton = container.find('button[data-validate]')

    toggleState = ->
      toDisable = requiredFields.not(':hidden').filter () ->
        $(this).val() == ''
      .length

      validateItemButton.attr("disabled", !!toDisable)

    toggleState()
    requiredFields.each ->
      $(this).on "selector:change change", toggleState

    container.bind 'visibility:change', toggleState

  E.setStorageUnitName = (container) ->
    container.find('.storing-fields:visible').last().find('.storage-unit-name').html(container.find('.storing-fields').first().find('.storage-unit-name').first().text())

  domObserver = new DOMMutationObserver(document)
  E.onDOMElementAdded = (selectorOrObj, callback) =>
    if !callback && typeof selectorOrObj == 'object'
      domObserver.addListeners selectorOrObj
    else
      domObserver.addListener selectorOrObj, callback

) ekylibre, jQuery
