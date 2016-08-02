#= require backend/golumn/helpers/knockout_globals

((ko, $) ->

  #connect items with observableArrays
  ko.bindingHandlers.sortable =
    init: (element, valueAccessor, allBindingsAccessor, data, context) ->
      $element = $(element)
      value = ko.utils.unwrapObservable(valueAccessor()) or {}
      templateOptions = ko.utils.prepareTemplateOptions(valueAccessor, 'foreach')
      sortable = {}
      startActual = undefined
      updateActual = undefined
      stripTemplateWhitespace element, templateOptions.name
      #build a new object that has the global options with overrides from the binding
      $.extend true, sortable, ko.bindingHandlers.sortable
      if value.options and sortable.options
        ko.utils.extend sortable.options, value.options
        delete value.options
      ko.utils.extend sortable, value
      #if allowDrop is an observable or a function, then execute it in a computed observable
      if sortable.connectClass and (ko.isObservable(sortable.allowDrop) or typeof sortable.allowDrop == 'function')
        ko.computed {
          read: ->
            `var value`
            value = ko.utils.unwrapObservable(sortable.allowDrop)
            shouldAdd = if typeof value == 'function' then value.call(this, templateOptions.foreach) else value
            ko.utils.toggleDomNodeCssClass element, sortable.connectClass, shouldAdd
            return
          disposeWhenNodeIsRemoved: element
        }, this
      else
        ko.utils.toggleDomNodeCssClass element, sortable.connectClass, sortable.allowDrop
      #wrap the template binding
      ko.bindingHandlers.template.init element, (->
        templateOptions
      ), allBindingsAccessor, data, context
      #keep a reference to start/update functions that might have been passed in
      startActual = sortable.options.start
      updateActual = sortable.options.update
      #initialize sortable binding after template binding has rendered in update function
      createTimeout = setTimeout((->
        dragItem = undefined
        $element.sortable ko.utils.extend(sortable.options,
          helper: (e, item) ->
            `var container`
            elements = []
            helper = undefined
            if ko.utils.domData.get(item[0], ko.constants.GROUPKEY) != undefined or ko.utils.domData.get(item[0], ko.constants.CONTAINERKEY) != undefined
#TODO: cause dragging issue
#helper = $(item[0]).addClass('group-dragging');
              helper = $(item[0])
            else if ko.utils.domData.get(item[0], ko.constants.ITEMKEY) != undefined
              elements = $('.checker.active').closest('.golumn-item').find('.golumn-item-title').clone()
              if !elements.length
                elements.push item.clone()
              helper = $('<div class=\'animate-dragging\' style=\'width: 130px; height: 30px\'></div>')
              if elements.length > 1
                helper.append $('<div class=\'animate-dragging-number\'>' + elements.length + '</div>')
                z = 0
                render = 3
                if elements.length < render
                  render = elements.length
                i = 0
                while i < render
                  t = -i * 5
                  container = $('<div style=\'width: 130px; height: 30px; color: white; vertical-align: middle; text-align: center; font-weight: bold; font-size:14px; line-height:20px; background-color: #428bca; box-shadow: 1px 1px 8px #000000;\'></div>')
                  $(container).css 'top', t + 'px'
                  $(container).css 'left', -t + 'px'
                  $(container).css 'z-index', z
                  container.append $(elements[i]).text()
                  container.addClass 'animate-dragging-img'
                  helper.append container
                  z = z - 1
                  i++
              else
                container = $('<div style=\'width: 130px; height: 30px; vertical-align: middle; text-align: center; font-size:14px; line-height:20px\'></div>')
                container.append $(elements[0]).text()
                container.addClass 'animate-dragging-text'
                helper.append container
            else
              #fallback
              helper = $('<div class=\'animate-dragging\' style=\'width:50px;height:50px\'></div>')
            helper
          sort: (event, ui) ->
            #var $target = $(event.target);
            #if (!/html|body/i.test($target.offsetParent()[0].tagName)) {
            #    var left = event.pageX - $target.offsetParent().offset().left - (ui.helper.outerHeight(true) / 2);
            #    ui.helper.css({'left' : left + 'px'});
            #}
            return
          start: (event, ui) ->
            #track original index
            el = ui.item[0]
            #Moving an animal
            if ko.utils.domData.get(el, ko.constants.ITEMKEY) != undefined
              el = $('.checker.active').closest('.golumn-item').not('.ui-sortable-placeholder')
              if el.length
                ui.item.data 'items', el
              $('.golumn-group .body .animal-dropzone').addClass 'grow-empty-zone'
              $('.add-container').css 'display', 'block'
              $('.add-container').addClass 'grow-empty-zone'
            if ko.utils.domData.get(el, ko.constants.GROUPKEY) != undefined
              #Need to set current array position
              ko.utils.domData.set el, ko.constants.INDEXKEY, ko.utils.arrayIndexOf(ui.item.parent().children(), el)
            containerItem = undefined
            if (containerItem = ko.utils.domData.get(el, ko.constants.CONTAINERKEY)) != undefined
              ko.utils.domData.set el, ko.constants.INDEXKEY, containerItem.position()
            #make sure that fields have a chance to update model
            ui.item.find('input:focus').change()
            if startActual
              startActual.apply this, arguments
            return
          over: (event, ui) ->
            sortableIn = 1
            $('.sorting-animal-placeholder').css 'display', 'block'
            return
          out: (event, ui) ->
            sortableIn = 0
            $('.sorting-animal-placeholder').css 'display', 'none'
            return
          receive: (event, ui) ->
            el = ui.item[0]
            if ko.utils.domData.get(el, ko.constants.ITEMKEY) != undefined and sortableIn
              containerEl = ui.item.closest('.golumn-group')[0]
              animals = []
              containerItem = undefined
              if containerEl != undefined
                containerItem = ko.utils.domData.get(containerEl, ko.constants.CONTAINERKEY)
                observableItem = undefined
                if ui.item.data('items')
                  el = ui.item.data('items')
                else
                  el = ui.item
                ko.utils.arrayForEach el, (item) ->
                  if (observableItem = ko.utils.domData.get(item, ko.constants.ITEMKEY)) != null
                    animals.push observableItem
                    $(item).remove()
                  return
              window.app.toggleMoveAnimalModal animals, containerItem
            if !sortableIn
              $(ui.sender or this).sortable 'cancel'
            return
          stop: (e, ui) ->
            el = ui.item[0]
            $('.golumn-group .body .animal-dropzone').removeClass 'grow-empty-zone'
            $('.add-container').removeClass 'grow-empty-zone'
            $('.add-container').css 'display', 'none'
            if ko.utils.domData.get(el, ko.constants.GROUPKEY) != undefined
              #$(el).removeClass('group-dragging');
            else
            return
          update: (event, ui) ->
            el = ui.item[0]
            if (observableItem = ko.utils.domData.get(el, ko.constants.GROUPKEY)) != undefined
              sourceParent = ko.utils.domData.get(el, PARENTKEY)
              sourceIndex = ko.utils.domData.get(el, ko.constants.INDEXKEY)
              targetParent = ko.utils.domData.get(el.parentNode, LISTKEY)
              targetIndex = ko.utils.arrayIndexOf(ui.item.parent().children(), el)
              #do the actual move
              if targetIndex >= 0
                if sourceParent
                  sourceParent.splice sourceIndex, 1
                targetParent.splice targetIndex, 0, observableItem
              #update preferences
              window.app.updatePreferences()
            if ko.utils.domData.get(el, ko.constants.CONTAINERKEY) != undefined
              sourceParentGroup = ko.utils.domData.get($(el).closest('.golumn-column')[0], ko.constants.GROUPKEY)
              sourceIndex = ko.utils.domData.get(el, ko.constants.INDEXKEY)
              targetParent = ko.utils.domData.get(ui.item.closest('.golumn-column')[0], ko.constants.GROUPKEY)
              targetIndex = ko.utils.arrayIndexOf(ui.item.parent().children(), el)
              containerItem = undefined
              containerItem = ko.utils.domData.get(el, ko.constants.CONTAINERKEY)
              if sourceParentGroup and targetParent and !isNaN(sourceIndex) and !isNaN(targetIndex)
                window.app.moveContainer containerItem, sourceParentGroup, sourceIndex, targetParent, targetIndex
            if updateActual
              updateActual.apply this, arguments
            return
          connectWith: if sortable.connectClass then '.' + sortable.connectClass else false)
        #handle enabling/disabling sorting
        if sortable.isEnabled != undefined
          ko.computed
            read: ->
              $element.sortable if ko.utils.unwrapObservable(sortable.isEnabled) then 'enable' else 'disable'
              return
            disposeWhenNodeIsRemoved: element
        return
      ), 0)
      #handle disposal
      ko.utils.domNodeDisposal.addDisposeCallback element, ->
        #only call destroy if sortable has been created
        if $element.data('ui-sortable') or $element.data('sortable')
          $element.sortable 'destroy'
        ko.utils.toggleDomNodeCssClass element, sortable.connectClass, false
        #do not create the sortable if the element has been removed from DOM
        clearTimeout createTimeout
        return
      { 'controlsDescendantBindings': true }
    update: (element, valueAccessor, allBindingsAccessor, data, context) ->
      templateOptions = ko.utils.prepareTemplateOptions(valueAccessor, 'foreach')
      #attach meta-data
      ko.utils.domData.set element, LISTKEY, templateOptions.foreach
      #call template binding's update with correct options
      ko.bindingHandlers.template.update element, (->
        templateOptions
      ), allBindingsAccessor, data, context
      return
    connectClass: 'ko_container'
    allowDrop: true
    afterMove: null
    beforeMove: null
    options: {}
) ko, jQuery