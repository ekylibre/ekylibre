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
            helper = $('<div class=\'animate-dragging\' style=\'width: 130px; height: 30px\'></div>')
            helper.append $('<div class=\'animate-dragging-number\'>' + keys.length + '</div>')
            container = $('<div style=\'width: 130px; height: 30px; color: white; vertical-align: middle; text-align: center; font-weight: bold; font-size:14px; line-height:20px; background-color: #428bca; box-shadow: 1px 1px 8px #000000;\'></div>')
            container.append elements[keys[0]].name
            container.addClass 'animate-dragging-text'
            helper.append container
            helper
          start: (event, ui) ->
            $('.add-container').css 'display', 'block'
            return
          stop: (e, ui) ->
            $('.add-container').css 'display', 'none'
            return
      else
        if $element.data('ui-draggable') or $element.data('draggable')
          $(element).draggable 'destroy'

    options: helper: 'clone'

) ko, jQuery