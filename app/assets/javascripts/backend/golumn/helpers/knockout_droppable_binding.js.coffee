#= require backend/golumn/helpers/knockout_globals

((ko, $) ->

  ko.bindingHandlers.droppable =

    init: (element, valueAccessor, allBindingsAccessor, data, context) ->
      $element = $(element)
      value = ko.utils.unwrapObservable(valueAccessor()) or {}
      droppable = {}
      dropActual = undefined

      $.extend true, droppable, ko.bindingHandlers.droppable

      if value.data

        if value.options and droppable.options
          ko.utils.extend droppable.options, value.options
          delete value.options

        ko.utils.extend droppable, value
      else
        droppable.data = value

      dropActual = droppable.options.drop

      $element.droppable ko.utils.extend(droppable.options,
        out: (e, ui) ->
        over: (e, ui) ->
          container = undefined
          if container = ko.utils.domData.get($(this)[0], ko.constants.CONTAINERKEY)
            container.hidden false
          return
        drop: (event, ui) ->
          sourceParent = undefined
          targetParent = undefined
          targetGroup = undefined
          targetIndex = undefined
          i = undefined
          targetUnwrapped = undefined
          arg = undefined
          el = ui.draggable[0]
          item = ko.utils.domData.get(el, ITEMKEY) or ko.utils.domData.get(el, ko.constants.DRAGKEY)
          if !sortableIn
            if item and item.clone
              item = item.clone()
            if item
              targetGroup = ko.utils.domData.get($(this).closest('.golumn-column')[0], ko.constants.GROUPKEY)
              el = ui.draggable.data('items')
              ko.utils.arrayForEach el, (item) ->
                if (observableItem = ko.utils.domData.get(item, ITEMKEY)) != null
                  window.app.droppedAnimals.push observableItem
                return
              window.app.toggleNewContainerModal targetGroup
              if dropActual
                dropActual.apply this, arguments
          return
      )

      #handle enabling/disabling
      if droppable.isEnabled != undefined
        ko.computed
          read: ->
            $element.droppable if ko.utils.unwrapObservable(droppable.isEnabled) then 'enable' else 'disable'
            return
          disposeWhenNodeIsRemoved: element
      return

    update: (element, valueAccessor, allBindingsAccessor, data, context) ->
      return
    targetIndex: null
    afterMove: null
    beforeMove: null
    options: {}
) ko, jQuery