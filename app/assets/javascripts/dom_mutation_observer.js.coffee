class DOMMutationObserver
  constructor: (element) ->
    @element = element
    @observer = null
    @listeners = []

  started: () -> @observer != null

  start: () ->
    _createObserver()
    _observe()

  addListener: (selector, callback) ->
    listeners.push
      selector: selector
      callback: callback
    start()

  addListeners: (hash) ->
    for selector,callback of selectorOrObj
      addListener selector, callback

  _createObserver: () ->
    @observer = new MutationObserver (mutationList, observer) =>
      for mutation in mutationList
        for listener in @listeners
          $element = $(listener.selector, mutation.addedNodes)
          listener.callback $element if $element.length
      return

  _observe: () -> @observer.observe(@element, {childList: true, subtree: true})