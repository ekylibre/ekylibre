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
      this.dropDownButton = $ "<a>",
          href: "##{this.element.attr('id')}"
          rel: 'dropdown'
          class: 'selector-dropdown'
        .append $("<i>")
        .insertAfter this.element
      this.lastSearch = this.element.val()
      this.dropDownMenu = $ "<div>",
          class: "items-menu"
        .hide()
        .insertAfter(this.element)
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
        # blur: "_focusOut"
      this._on this.dropDownButton,
        click: "_unrollClick"
        focusout: "_focusOut"
        # blur: "_focusOut"
      this._on this.dropDownMenu,
        "click ul li.item": "_menuClick"
        "mouseenter ul li.item": "_menuMouseEnter"
        # "hover ul li.item": "_menuMouseEnter"
      this.sourceURL = this.element.data("selector")
      this._set this.element.val()

    value: (newValue) ->
      if newValue is null or newValue is undefined or newValue is ""
        return this.valueField.val()
      this._set(newValue)

    _set: (id, triggerEvents = false) ->
      if id is null or id is undefined or id is ""
        return this.valueField.val()
      that = this
      $.ajax
        url: this.sourceURL,
        dataType: "json"
        data:
          id: id
        success: (data, status, request) ->
          listItem = $.parseJSON(request.responseText)[0]
          if listItem?
            that._select listItem.id, listItem.label, triggerEvents
          else
            console.log "JSON cannot be parsed. Get: #{request.responseText}."
        error: (request, status, error) ->
          alert "Cannot get details of item on #{this.sourceURL} (#{status}): #{error}"
      this

    _select: (id, label, triggerEvents = false) ->
      console.log "select"
      this.lastSearch = label
      len = 10 * Math.round(Math.round(1.5 * label.length) / 10)
      this.element.attr "size", (if len < 20 then 20 else (if len > 80 then 80 else len))
      this.element.val label
      this.valueField.prop "itemLabel", label
      this.valueField.val id
      this.id = parseInt id
      if this.dropDownMenu.is(":visible")
        this.dropDownMenu.hide()
      if triggerEvents is true
        this.element.trigger "selector:change"
      this

    _openMenu: (search) ->
      console.log "openMenu"
      data = {}
      if search?
        data.q = search
      if this.element.data("with")
        $(this.element.data("with")).each ->
          paramName = $(this).data("parameter-name") || $(this).attr("name") || $(this).attr("id")
          if paramName?
            data[paramName] = $(this).val() || $.trim($(this).html())
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
      console.log "closeMenu"
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
      console.log "choose"
      selected ?= this.dropDownMenu.find("ul li.item.selected").first()
      if selected.length > 0
        if selected.is("[data-item-label][data-item-id]")
          this._select(selected.data("item-id"), selected.data("item-label"), true)
        else if selected.is("[data-new-item]")
          parameters = {}
          if selected.data("new-item").length > 0
            parameters.name = selected.data("new-item")
          that = this
          $.ajaxDialog this.element.data("selector-new-item"),
            data: parameters
            returns:
              success: (frame, data, status, request) ->
                that._set(request.getResponseHeader("X-Saved-Record-Id"), true)
                frame.dialog "close"
              invalid: (frame, data, status, request) ->
                frame.html request.responseText
        else
          console.log "Don't known how to manage this option"
          console.log selected
          alert "Don't known how to manage this option"
      else
        console.log "No selected item to choose..."
      this

    _keypress: (event) ->
      code = (event.keyCode or event.which)
      if code is 13 or code is 10 # Enter
        if this.dropDownMenu.is(":visible")
          this._choose()
          return false
      else if code is 40 # Down
        if this.dropDownMenu.is(":hidden")
          this._openMenu(this.element.val())
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
      console.log "focusout"
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
      console.log "menuclick"
      console.log event.target
      this._choose()
      false

    _menuMouseEnter: (event) ->
      item = $(event.target)
      item.closest("ul").find("li.item.selected").removeClass "selected"
      item.addClass "selected"
      false

  $(document).behave "load", "input[data-selector]", (event) ->
    $("input[data-selector]").each ->
      $(this).selector()

  return
) jQuery
