#= require backend/golumn/helpers/knockout_globals
((ko, $) ->

  ko.bindingHandlers.draggable =
    init: (element, valueAccessor, allBindingsAccessor, data, context) ->
      $element = $(element)
      value = ko.utils.unwrapObservable(valueAccessor()) or {}
      options = value.options or {}
      draggableOptions = ko.utils.extend({}, ko.bindingHandlers.draggable.options)
      templateOptions = ko.utils.prepareTemplateOptions(valueAccessor, 'foreach')
      connectClass = value.connectClass or ko.bindingHandlers.draggable.connectClass
      isEnabled = if value.isEnabled != undefined then value.isEnabled else ko.bindingHandlers.draggable.isEnabled

      # value = "data" in value ? value.data : value;
      # value = "foreach" in value ? value.foreach : value;
      # console.log(element, ko.utils.unwrapObservable(valueAccessor()));
      #set meta-data
      ko.utils.domData.set element, ko.constants.DRAGKEY, value
      #override global options with override options passed in
      ko.utils.extend draggableOptions, options
      #setup connection to a sortable
      # draggableOptions.connectToSortable = connectClass ? "." + connectClass : false;
      #initialize draggable
      # $(element).draggable(draggableOptions);
      ko.bindingHandlers.template.init element, (->
        templateOptions
      ), allBindingsAccessor, data, context
      createTimeout = setTimeout((->
        $(element).draggable ko.utils.extend(draggableOptions,
          helper: (e) ->
            elements = []
            helper = undefined
            elements = $('.checker.active').closest('.golumn-item').find('.golumn-item-title')
            if !elements.length
              item = $(e.target).siblings('.golumn-item-title')
              if item.length > 0
                elements.push item
            helper = $('<div class=\'animate-dragging\' style=\'width: 130px; height: 30px\'></div>')
            helper.append $('<div class=\'animate-dragging-number\'>' + elements.length + '</div>')
            container = $('<div style=\'width: 130px; height: 30px; color: white; vertical-align: middle; text-align: center; font-weight: bold; font-size:14px; line-height:20px; background-color: #428bca; box-shadow: 1px 1px 8px #000000;\'></div>')
            container.append $(elements[0]).text()
            container.addClass 'animate-dragging-text'
            helper.append container
            helper
          start: (event, ui) ->
            $('.golumn-group .body .animal-dropzone').addClass 'grow-empty-zone'
            $('.add-container').css 'display', 'block'
            $('.add-container').addClass 'grow-empty-zone'
            return
          stop: (e, ui) ->
            $('.golumn-group .body .animal-dropzone').removeClass 'grow-empty-zone'
            $('.add-container').removeClass 'grow-empty-zone'
            $('.add-container').css 'display', 'none'
            return
        )
        #handle enabling/disabling sorting
        if isEnabled != undefined
          ko.computed
            read: ->
              $(element).draggable if ko.utils.unwrapObservable(isEnabled) then 'enable' else 'disable'
              return
            disposeWhenNodeIsRemoved: element
        return
      ), 0)

      ko.utils.domNodeDisposal.addDisposeCallback element, ->

        #only call destroy if draggable has been created
        if $element.data('ui-draggable') or $element.data('draggable')
          $element.draggable 'destroy'

        ko.utils.toggleDomNodeCssClass element, draggable.connectClass, false
        #do not create the sortable if the element has been removed from DOM
        clearTimeout createTimeout

        return

      { 'controlsDescendantBindings': true }

    update: (element, valueAccessor, allBindingsAccessor, data, context) ->
      templateOptions = ko.utils.prepareTemplateOptions(valueAccessor, 'foreach')
#      ko.utils.domData.set element, ko.constants.LISTKEY, templateOptions.foreach
      ko.bindingHandlers.template.update element, (->
        templateOptions
      ), allBindingsAccessor, data, context
    options: helper: 'clone'

) ko, jQuery