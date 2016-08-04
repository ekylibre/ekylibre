#= require backend/golumn/helpers/knockout_globals

((ko, $) ->

  ko.bindingHandlers.droppable =

    init: (element, valueAccessor, allBindingsAccessor, data, context) ->
      $element = $(element)
      value = ko.utils.unwrapObservable(valueAccessor()) or {}
      options = value.options or {}
      droppableOptions = ko.utils.extend({}, ko.bindingHandlers.droppable.options)

      #override global options with override options passed in
      ko.utils.extend droppableOptions, options

      createTimeout = setTimeout((->
        $element.droppable ko.utils.extend(droppableOptions,
          out: (e, ui) ->
            return
          over: (e, ui) ->
            return
          drop: (event, ui) ->
            target = context.$data

            if target

              if target.constructor.name is 'Group'
                #dropped on empty dropzone
                app.toggleNewContainerModal target

              else if target.constructor.name is 'Container'
                #on existing container
                app.toggleMoveAnimalModal target

              return
        )
      ), 0)

      ko.utils.domNodeDisposal.addDisposeCallback element, ->

        #only call destroy if draggable has been created
        if $element.data('ui-droppable') or $element.data('droppable')
          $element.draggable 'destroy'

        clearTimeout createTimeout

        return

      return

    update: (element, valueAccessor, allBindingsAccessor, data, context) ->
      return
    targetIndex: null
    afterMove: null
    beforeMove: null
    options: {}
) ko, jQuery