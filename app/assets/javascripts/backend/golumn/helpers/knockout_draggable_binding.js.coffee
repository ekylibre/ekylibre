#= require backend/golumn/helpers/knockout_globals
((ko, $) ->

  ko.bindingHandlers.draggable =
    init: (element, valueAccessor, allBindingsAccessor) ->
      $element = $(element)

      ko.utils.domNodeDisposal.addDisposeCallback element, ->

        #only call destroy if draggable has been created
        if $element.data('ui-draggable') or $element.data('draggable')
          $element.draggable 'destroy'

    update: (element, valueAccessor, allBindingsAccessor, data, context) ->
      $element = $(element)
      value = ko.utils.unwrapObservable(valueAccessor()) or {}
      draggableOptions = ko.utils.extend({}, value.options || {})

      if ko.utils.unwrapObservable(value.active)

        $(element).draggable ko.utils.extend draggableOptions,
          helper: (e) ->
            elements = app.selectedItemsIndex
            keys = Object.keys(elements)
            helper = $("<div class='animate-dragging' data-count='#{keys.length}'></div>")
            container = $("<div class='animate-dragging-text'>#{elements[keys[0]].name}</div>")
            helper.append container
            helper
          start: (event, ui) ->
            context.$root.enableDropZones(true)
            return
          stop: (e, ui) ->
            context.$root.enableDropZones(false)
            return
      else
        if $element.data('ui-draggable') or $element.data('draggable')
          $(element).draggable 'destroy'

    options: helper: 'clone'

) ko, jQuery