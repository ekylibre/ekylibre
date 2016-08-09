#= require backend/golumn/helpers/knockout_globals

((ko, $) ->

  ko.bindingHandlers.droppable =

    init: (element, valueAccessor, allBindingsAccessor) ->
      $element = $(element)

      ko.utils.domNodeDisposal.addDisposeCallback element, ->

        #only call destroy if droppable has been created
        if $element.data('ui-droppable') or $element.data('droppable')
          $element.droppable 'destroy'

      return

    update: (element, valueAccessor, allBindingsAccessor, data, context) ->
      $element = $(element)
      value = ko.utils.unwrapObservable(valueAccessor()) or {}
      droppableOptions = ko.utils.extend({}, value.options || {})

      if ko.utils.unwrapObservable(value.active)

        $element.droppable ko.utils.extend droppableOptions,
          out: (e, ui) ->
            return
          over: (e, ui) ->
            return
          drop: (event, ui) ->
            target = context.$data

            if target

              container = undefined
              group = target

              if target.constructor.name is 'Container'
                container = target
                group = target.parent

              app.moveAnimals container, group

              return

      else
        if $element.data('ui-droppable') or $element.data('droppable')
          $element.droppable 'destroy'

    targetIndex: null
    afterMove: null
    beforeMove: null
    options: {}
) ko, jQuery