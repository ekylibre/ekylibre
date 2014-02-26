# Selectors for unroll action
#= require jquery.scrollTo
# 
(($) ->
  "use strict"
 
  $.widget "ui.selector",
    options:
      clear: false

    id: null

    _create: ->
      this.element.attr "autocomplete", "off"
      this.dropDownButton = $("<a><i></i></a>")
        .attr
          href: "##{this.element.attr('id')}"
          rel: 'dropdown'
          class: 'selector-dropdown'
        .insertAfter this.element
      this.lastSearch = this.element.val()
      this.dropDownMenu = $ "<div>",
        class: "items-menu"
      this.dropDownMenu.hide().insertAfter(this.element)
      if this.element.data("valueField")?
        this.valueField = $ this.element.data("valueField")
      else
        this.valueField = $ "<input type='hidden' name='#{this.element.attr('name')}'/>"
        this.element.after this.valueField
      this.element.removeAttr "name"
      if this.element.attr("required") is "true"
        this.valueField.attr "required", "true"
      this._on this.element,
        keypress: "_keypress"
        keyup: "_keyup"
        focusout: "_focusOut"
        blur: "_focusOut"
      this._on this.dropDownButton,
        click: "_unrollClick"
        focusout: "_focusOut"
        blur: "_focusOut"
      this._on this.dropDownMenu,
        "click ul li.item": "_menuClick"
        "mouseenter ul li.item": "_menuMouseEnter"
        "hover ul li.item": "_menuMouseEnter"
      this.sourceURL = this.element.data("selector")
      this._set this.element.val()

    value: (newValue) ->
      return this.id unless newValue?
      console.log "Set new value #{newValue}!"
      this._set(newValue)
                  
    _set: (id) ->
      return this.id if id is null or id is undefined or id is ""
      $.ajax
        url: this.sourceURL,
        dataType: "json"
        data:
          id: id
        success: (data, status, request) ->
          listItem = $.parseJSON(request.responseText)[0]
          if listItem?
            this._select listItem.id, listItem.label
          else
            console.log "JSON cannot be parsed. Get: #{request.responseText}."
        error: (request, status, error) ->
          alert "Cannot get details of item on #{this.sourceURL} (#{status}): #{error}"
      this
      

    _select: (id, label) ->
      this.lastSearch = label
      len = 10 * Math.round(Math.round(1.5 * label.length) / 10)
      this.element.attr "size", ((if len < 20 then 20 else (if len > 80 then 80 else len)))
      this.element.val label
      this.valueField.prop "itemLabel", label
      this.valueField.val id
      this.id = parseInt id
      if this.dropDownMenu.is(":visible")
        this.dropDownMenu.hide() 
      this.element.trigger "change"
      # this.valueField.trigger "change"
      this

    _openMenu: (search) ->
      data = {}
      if search?
        data.q = search
      if this.element.data("with")
        $(this.element.data("with")).each ->
          paramName = $(this).data("parameter-name") || $(this).attr("name") || $(this).attr("id")
          if paramName?
            data[paramName] = $(this).val() || $.trim($(this).html())
          return
      menu = this.dropDownMenu
      $.ajax
        url: this.sourceURL
        dataType: "html"
        data: data
        success: (data, status, request) ->
          menu.html data
          if data.length > 0
            menu.show()
          else
            menu.hide()
        error: (request, status, error) ->
          alert "Selector failure on #{this.sourceURL} (#{status}): #{error}"

    _closeMenu: ->
      if this.element.attr("required") is "true"        
        # Restore last value if possible
        if this.valueField.val().length > 0
          search = this.valueField.prop("itemLabel")  
      else
        # Empty values if empty
        if this.element.val().length <= 0
          this.valueField.val ""
          search = ""
        else if this.valueField.val().length > 0
          search = this.valueField.prop("itemLabel") 
      this.lastSearch = search
      this.element.val search
      if this.dropDownMenu.is(":visible")
        this.dropDownMenu.hide() 
      true

    _choose: (selected) ->
      selected ?= this.dropDownMenu.find("ul li.selected.item").first()
      if selected[0]?
        if selected.is("[data-item-label][data-item-id]")
          this._select selected.data("itemId"), selected.data("itemLabel")
        else if selected.is("[data-new-item]")
          parameters = {}
          if selected.data("newItem").length > 0
            parameters.name = selected.data("newItem")  
          $.ajaxDialog this.element.data("selectorNewItem"),
            data: parameters
            returns:
              success: (frame, data, status, request) ->
                this._set request.getResponseHeader("X-Saved-Record-Id")
                frame.dialog "close"
              invalid: (frame, data, textStatus, request) ->
                frame.html request.responseText
        else
          alert "Don't known how to manage this option"
          console.log "Don't known how to manage this option"
      else
        console.log "No selected item to choose..."
      this
    
      
    _keypress: (event) ->
      code = (event.keyCode or event.which)
      if code is 13 or code is 10 # Enter
        if this.dropDownMenu.is(":visible")
          this._choose
          return false
      else if code is 40 # Down
        if this.dropDownMenu.is(":hidden")
          this._openMenu this.element.val()
          return false
      true
    

    _keyup: (event) -> 
      code = (event.keyCode or event.which)
      search = this.element.val()
      if this.lastSearch isnt search
        if search.length > 0
          this._openMenu search
        else
          this.dropDownMenu.hide()
        this.lastSearch = search
      else if this.dropDownMenu.is(":visible")
        selected = this.dropDownMenu.find("ul li.selected.item").first()
        if code is 27 # Escape
          this.dropDownMenu.hide()
        else if selected[0] is null or selected[0] is undefined
          selected = this.dropDownMenu.find("ul li.item").first()
          selected.addClass "selected"
        else
          if code is 40 # Down
            unless selected.is(":last-child")
              selected.removeClass "selected"
              # selected.closest("ul").scrollTo
              selected.next().addClass "selected"
          else if code is 38 # Up
            unless selected.is(":first-child")
              selected.removeClass "selected"
              # selected.closest("ul").scrollTo
              selected.prev().addClass "selected"
      true

    _focusOut: (event) ->
      # this._closeMenu()
      that = this
      setTimeout ->
        that._closeMenu()
      , 300
      true

    _unrollClick: (event) ->
      if this.dropDownMenu.is(":visible")
        this.dropDownMenu.hide()
      else
        this._openMenu()
      false
      
    _menuClick: (event) ->
      this._choose $(event.target)
      false

    _menuMouseEnter: (event) ->
      item = $(event.target)
      item.closest("ul").find("li.item.selected").removeClass "selected"
      item.addClass "selected"
      false
                 
  $(document).ready ->
    $("input[data-selector]").each ->
      $(this).selector()

  # $.EkylibreSelector =
  #   init: (element) ->
  #     selector = $(element)
  #     name = undefined
  #     hidden = undefined
  #     menu = undefined
  #     button = undefined
  #     selector.attr "autocomplete", "off"
  #     if selector.prop("dropDownButton") is `undefined`
  #       button = $("<a href='#" + selector.attr("id") + "' rel='dropdown' class='selector-dropdown'><i></i></a>")
  #       button.prop "selector", selector
  #       selector.after button
  #       selector.prop "lastSearch", selector.val()
  #       selector.prop "dropDownButton", button
  #     if selector.prop("dropDownMenu") is `undefined`
  #       menu = $("<div class=\"items-menu\"></div>")
  #       menu.hide()
  #       menu.prop "selectorOfMenu", selector
  #       selector.after menu
  #       selector.prop "dropDownMenu", menu
  #     if selector.prop("hiddenInput") is `undefined`
  #       if element.data("value-field") isnt `undefined`
  #         hidden = $(element.data("value-field"))
  #       else
  #         name = selector.attr("name")
  #         hidden = $("<input type='hidden' name='" + name + "'/>")
          
  #         # selector.closest("form").prepend(hidden);
  #         selector.after hidden
  #       selector.removeAttr "name"
  #       hidden.attr "required", "true"  if selector.attr("required") is "true"
  #       selector.prop "hiddenInput", hidden
  #     $.EkylibreSelector.set selector, selector.val()
  #     selector

  #   initAll: ->
  #     $("input[data-selector]").each (index) ->
  #       $.EkylibreSelector.init $(this)
  #       return

  #     true

  #   getSourceURL: (element) ->
  #     selector = element
      
  #     # Adds data-change-source management
  #     selector.data "selector"

  #   closeMenu: (element) ->
  #     selector = element
  #     menu = undefined
  #     hidden = undefined
  #     search = undefined
  #     menu = selector.prop("dropDownMenu")
  #     hidden = selector.prop("hiddenInput")
  #     if selector.attr("required") is "true"
        
  #       # Restore last value if possible
  #       search = hidden.prop("itemLabel")  if hidden.val().length > 0
  #     else
        
  #       # Empty values if empty
  #       if selector.val().length <= 0
  #         hidden.val ""
  #         search = ""
  #       else search = hidden.prop("itemLabel")  if hidden.val().length > 0
  #     selector.prop "lastSearch", search
  #     selector.val search
  #     menu.hide()  if menu.is(":visible")
  #     selector

  #   openMenu: (element, search) ->
  #     selector = element
  #     data = {}
  #     menu = undefined
  #     menu = selector.prop("dropDownMenu")
  #     data = q: search  if search isnt `undefined`
  #     if element.data("with")
  #       $(element.data("with")).each ->
  #         paramName = $(this).data("parameter-name") or $(this).attr("name") or $(this).attr("id")
  #         data[paramName] = $(this).val() or $.trim($(this).html())  if paramName isnt null and (typeof (paramName) isnt `undefined`)
  #         return

  #     $.ajax $.EkylibreSelector.getSourceURL(selector),
  #       dataType: "html"
  #       data: data
  #       success: (data, status, request) ->
  #         menu.html data
  #         if data.length > 0
  #           menu.show()
  #         else
  #           menu.hide()
  #         return

  #       error: (request, status, error) ->
  #         alert "Selector failure on " + selector.data("selector") + " (" + status + "): " + error
  #         return


  #   select: (element, id, label) ->
  #     selector = element
  #     menu = undefined
  #     hidden = undefined
  #     len = undefined
  #     menu = selector.prop("dropDownMenu")
  #     hidden = selector.prop("hiddenInput")
  #     selector.prop "lastSearch", label
  #     selector.val label
  #     len = 10 * Math.round(Math.round(1.5 * label.length) / 10)
  #     selector.attr "size", ((if len < 20 then 20 else (if len > 80 then 80 else len)))
  #     hidden.prop "itemLabel", label
  #     hidden.val id
  #     menu.hide()  if menu.is(":visible")
  #     selector

  #   set: (element, id) ->
  #     selector = element
  #     if id isnt `undefined` and id isnt ""
  #       $.ajax $.EkylibreSelector.getSourceURL(selector),
  #         dataType: "json"
  #         data:
  #           id: id

  #         success: (data, status, request) ->
  #           list_item = $.parseJSON(request.responseText)[0]
  #           if list_item is `undefined` or list_item is null
  #             console.log "JSON cannot be parsed. Get: " + request.responseText
  #           else
  #             $.EkylibreSelector.select selector, list_item.id, list_item.label
  #           return

  #         error: (request, status, error) ->
  #           alert "Cannot get details of item on " + selector.data("selector") + " (" + status + "): " + error
  #           return

  #     selector

  #   choose: (element, selected) ->
  #     selector = element
  #     parameters = undefined
  #     menu = undefined
  #     if selected is `undefined`
  #       menu = selector.prop("dropDownMenu")
  #       selected = menu.find("ul li.selected.item").first()
  #     if selected[0] isnt null and selected[0] isnt `undefined`
  #       if selected.is("[data-item-label][data-item-id]")
  #         $.EkylibreSelector.select selector, selected.data("item-id"), selected.data("item-label")
  #         selector.trigger "change"
  #         selector[0].hiddenInput.trigger "change"
  #       else if selected.is("[data-new-item]")
  #         parameters = {}
  #         parameters = name: selected.data("new-item")  if selected.data("new-item").length > 0
  #         $.ajaxDialog selector.data("selector-new-item"),
  #           data: parameters
  #           returns:
  #             success: (frame, data, status, request) ->
  #               record_id = request.getResponseHeader("X-Saved-Record-Id")
  #               $.EkylibreSelector.set selector, record_id
  #               selector.trigger "change"
  #               selector[0].hiddenInput.trigger "change"
  #               frame.dialog "close"
  #               return

  #             invalid: (frame, data, textStatus, request) ->
  #               frame.html request.responseText
  #               return

  #       else
  #         alert "Don't known how to manage this option"
  #         console.log "Don't known how to manage this option"
  #     else
  #       console.log "No selected item to choose..."
  #     selector

  # $(document).on "keypress", "input[data-selector]", (event) ->
  #   selector = $(this)
  #   menu = undefined
  #   code = (event.keyCode or event.which)
  #   menu = selector.prop("dropDownMenu")
  #   if code is 13 or code is 10 # Enter
  #     if menu.is(":visible")
  #       $.EkylibreSelector.choose selector
  #       return false
  #   else if code is 40 # Down
  #     if menu.is(":hidden")
  #       $.EkylibreSelector.openMenu selector, selector.val()
  #       return false
  #   true

  # $(document).on "keyup", "input[data-selector]", (event) ->
  #   selector = $(this)
  #   search = undefined
  #   menu = undefined
  #   code = (event.keyCode or event.which)
  #   selected = undefined
  #   search = selector.val()
  #   menu = selector.prop("dropDownMenu")
  #   if selector.prop("lastSearch") isnt search
  #     if search.length > 0
  #       $.EkylibreSelector.openMenu selector, search
  #     else
  #       menu.hide()
  #     selector.prop "lastSearch", search
  #   else if menu.is(":visible")
  #     selected = menu.find("ul li.selected.item").first()
  #     if code is 27 # Escape
  #       menu.hide()
  #     else if selected[0] is null or selected[0] is `undefined`
  #       selected = menu.find("ul li.item").first()
  #       selected.addClass "selected"
  #     else
  #       if code is 40 # Down
  #         unless selected.is(":last-child")
  #           selected.removeClass "selected"
  #           selected.next().addClass "selected"
  #       else if code is 38 # Up
  #         unless selected.is(":first-child")
  #           selected.removeClass "selected"
  #           selected.prev().addClass "selected"
  #   true

  # $(document).on "blur focusout", "input[data-selector]", (event) ->
  #   selector = $(this)
  #   setTimeout (->
  #     $.EkylibreSelector.closeMenu selector
  #     return
  #   ), 300
  #   true

  # $(document).on "click", "a.selector-dropdown[rel=\"dropdown\"][href]", (event) ->
  #   element = $(this)
  #   selector = undefined
  #   menu = undefined
  #   selector = element.prop("selector") #$(element.attr("href"));
  #   menu = selector.prop("dropDownMenu")
  #   if menu.is(":visible")
  #     menu.hide()
  #   else
  #     $.EkylibreSelector.openMenu selector
  #   false

  # $(document).on "blur focusout", "a.selector-dropdown[rel=\"dropdown\"][href]", (event) ->
  #   element = $(this)
  #   selector = undefined
  #   menu = undefined
  #   selector = element.prop("selector") #$(element.attr("href"));
  #   setTimeout (->
  #     $.EkylibreSelector.closeMenu selector
  #     return
  #   ), 300
  #   true

  # $(document).on "mouseenter hover", ".items-menu ul li.item", (event) ->
  #   element = $(this)
  #   list = undefined
  #   list = element.closest("ul")
  #   list.find("li.item.selected").removeClass "selected"
  #   element.addClass "selected"
  #   false

  # $(document).on "click", ".items-menu ul li.item", (event) ->
  #   selected = $(this)
  #   selector = selected.closest(".items-menu").prop("selectorOfMenu")
  #   $.EkylibreSelector.choose selector, selected
  #   false

  
  # # First initialization
  # # $(document).ready($.EkylibreSelector.initAll);
  # # $(document).ajaxComplete($.EkylibreSelector.initAll);
  
  # # Other initializations
  # $(document).behave "load", "input[data-selectorz]", (event) ->
  #   $.EkylibreSelector.init $(this)
  #   true

  
  # # do not remove for instance because of Capybara navigation and other
  # # see @burisu for authorization
  # $(document).ready ->
  #   $("input[data-selectorz]").each ->
  #     $.EkylibreSelector.init $(this)
  #     return

  #   return

  return
) jQuery
