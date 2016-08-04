#= require backend/golumn/helpers/knockout_globals

((ko, $) ->

  ko.bindingHandlers.droppable =

    init: (element, valueAccessor, allBindingsAccessor, data, context) ->
      $element = $(element)
      value = ko.utils.unwrapObservable(valueAccessor()) or {}
      options = value.options or {}
      droppableOptions = ko.utils.extend({}, ko.bindingHandlers.droppable.options)
      droppable = {}
      dropActual = undefined

      #override global options with override options passed in
      ko.utils.extend droppableOptions, options

      ko.utils.domData.set element, ko.constants.DROPKEY, data



      createTimeout = setTimeout((->
        $element.droppable ko.utils.extend(droppableOptions,
          out: (e, ui) ->
            return
          over: (e, ui) ->
#            container = undefined
#            if container = ko.utils.domData.get($(this)[0], ko.constants.CONTAINERKEY)
#              container.hidden false
            return
          drop: (event, ui) ->
            target = ko.utils.domData.get event.target, ko.constants.DROPKEY

            if target
              els = ui.draggable.data('items')
              items = ko.utils.arrayMap els, (item) ->
                ko.utils.domData.get(item, ko.constants.ITEMKEY)

              if target.constructor.name is 'Group'
                #dropped on empty dropzone
                window.app.toggleNewContainerModal target, items

              else if target.constructor.name is 'Container'
                #on existing container
                return


#            console.log 'i am a dropzone',
#                if (observableItem = ko.utils.domData.get(item, ko.constants.ITEMKEY)) != null
#                  window.app.droppedAnimals.push observableItem
#                return
#              window.app.toggleNewContainerModal targetGroup
#              if dropActual
#                dropActual.apply this, arguments
              return
        )
      ), 0)

      ko.utils.domNodeDisposal.addDisposeCallback element, ->

        #only call destroy if draggable has been created
        if $element.data('ui-droppable') or $element.data('droppable')
          $element.draggable 'destroy'

#        ko.utils.toggleDomNodeCssClass element, draggable.connectClass, false
        clearTimeout createTimeout

        return

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