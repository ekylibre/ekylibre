#= require backend/golumn/helpers/knockout_globals

((ko, $) ->

  ko.bindingHandlers.checkbox =
    init: (element, valueAccessor, allBindings, data, context) ->
      observable = valueAccessor()
      if !ko.isWriteableObservable(observable)
        throw 'You must pass an observable or writeable computed'
      $element = $(element)
      $element.on 'click', ->
        observable !observable()
        return
      ko.computed
        disposeWhenNodeIsRemoved: element
        read: ->
          $element.toggleClass 'active', observable()
          return
      return

  ko.bindingHandlers.modal =
    init: (element, valueAccessor) ->
      $(element).modal show: false
      value = valueAccessor()
      if typeof value == 'function'
        $(element).on 'hide.bs.modal', ->
          value false
          return
      ko.utils.domNodeDisposal.addDisposeCallback element, ->
        $(element).modal 'destroy'
        return
      return

    update: (element, valueAccessor) ->
      value = valueAccessor()
      if ko.utils.unwrapObservable(value)
        $(element).modal 'show'
      else
        $(element).modal 'hide'
      return

  ko.bindingHandlers.selector =
    init: (element, valueAccessor) ->
      $el = $(element)
      value = ko.utils.unwrapObservable(valueAccessor())

    update: (element, valueAccessor) ->
      $el = $(element)
      value = ko.utils.unwrapObservable(valueAccessor())
      return if value is undefined
      if value.id() is undefined
        $el.selector('clear')
      else
        $el.selector('value', value.id())

      $el.one 'selector:change', ->
        value.id $("input[name=#{$el.attr('id')}]").val()
        value.name =  $el.val()


) ko, jQuery