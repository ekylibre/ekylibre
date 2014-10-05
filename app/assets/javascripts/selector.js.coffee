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
      @element.attr "autocomplete", "off"
      @dropDownButton = $ "<a>",
          href: "##{@element.attr('id')}"
          rel: 'dropdown'
          tabindex: -1
          class: 'selector-dropdown'
        .append $("<i>")
        .insertAfter @element
      @lastSearch = @element.val()
      @dropDownMenu = $ "<div>",
          class: "items-menu"
        .hide()
        .insertAfter(@element)
      if @element.data("valueField")?
        @valueField = $ @element.data("valueField")
      else
        @valueField = $ "<input type='hidden' name='#{@element.attr('name')}'/>"
        @element.after @valueField
      @element.removeAttr "name"
      if @element.attr("required") is "true"
        @valueField.attr "required", "true"
      this._on @element,
        keypress: "_keypress"
        keyup: "_keyup"
        focusout: "_focusOut"
        # blur: "_focusOut"
      this._on @dropDownButton,
        click: "_unrollClick"
        focusout: "_focusOut"
        # blur: "_focusOut"
      this._on @dropDownMenu,
        "click ul li.item": "_menuClick"
        "mouseenter ul li.item": "_menuMouseEnter"
        # "hover ul li.item": "_menuMouseEnter"
      this.sourceURL = @element.data("selector")
      if @valueField.val()? and @valueField.val().length > 0
        this._set @valueField.val()
      else if @element.val()? and @element.val().length > 0
        this._set @element.val()

    value: (newValue) ->
      if newValue is null or newValue is undefined or newValue is ""
        return @valueField.val()
      this._set(newValue)

    _set: (id, triggerEvents = false) ->
      if id is null or id is undefined or id is ""
        return @valueField.val()
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
      # console.log "select"
      @lastSearch = label
      len = 10 * Math.round(Math.round(1.5 * label.length) / 10)
      @element.attr "size", (if len < 20 then 20 else (if len > 80 then 80 else len))
      @element.val label
      @valueField.prop "itemLabel", label
      @valueField.val id
      this.id = parseInt id
      if @dropDownMenu.is(":visible")
        @dropDownMenu.hide()
      if triggerEvents is true
        @element.trigger "selector:change"
      this

    _openMenu: (search) ->
      # console.log "openMenu"
      data = {}
      if search?
        data.q = search
      if @element.data("with")
        $(@element.data("with")).each ->
          paramName = $(this).data("parameter-name") || $(this).attr("name") || $(this).attr("id")
          if paramName?
            data[paramName] = $(this).val() || $.trim($(this).html())
      menu = @dropDownMenu
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
      # console.log "closeMenu"
      if @element.attr("required") is "true"
        # Restore last value if possible
        if @valueField.val().length > 0
          search = @valueField.prop("itemLabel")
      else
        # Empty values if empty
        if @element.val().length <= 0
          @valueField.val ""
          search = ""
        else if @valueField.val().length > 0
          search = @valueField.prop("itemLabel")
      @lastSearch = search
      @element.val search
      if @dropDownMenu.is(":visible")
        @dropDownMenu.hide()
      true

    _choose: (selected) ->
      # console.log "choose"
      selected ?= @dropDownMenu.find("ul li.item.selected").first()
      if selected.length > 0
        if selected.is("[data-item-label][data-item-id]")
          this._select(selected.data("item-id"), selected.data("item-label"), true)
        else if selected.is("[data-new-item]")
          parameters = {}
          if selected.data("new-item").length > 0
            parameters.name = selected.data("new-item")
          that = this
          $.ajaxDialog @element.data("selector-new-item"),
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
        if @dropDownMenu.is(":visible")
          this._choose()
          return false
      else if code is 40 # Down
        if @dropDownMenu.is(":hidden")
          this._openMenu(@element.val())
          return false
      true


    _keyup: (event) ->
      code = (event.keyCode or event.which)
      search = @element.val()
      if @lastSearch isnt search
        if search.length > 0
          this._openMenu search
        else
          @dropDownMenu.hide()
        @lastSearch = search
      else if @dropDownMenu.is(":visible")
        selected = @dropDownMenu.find("ul li.selected.item").first()
        if code is 27 # Escape
          @dropDownMenu.hide()
        else if selected[0] is null or selected[0] is undefined
          selected = @dropDownMenu.find("ul li.item").first()
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
      # console.log "focusout"
      that = this
      setTimeout ->
        that._closeMenu()
      , 300
      true

    _unrollClick: (event) ->
      if @dropDownMenu.is(":visible")
        @dropDownMenu.hide()
      else
        this._openMenu()
      false

    _menuClick: (event) ->
      # console.log "menuclick"
      # console.log event.target
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
