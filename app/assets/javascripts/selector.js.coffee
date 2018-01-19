# Selectors for unroll action
#= require jquery.scrollTo


((E, $) ->
  "use strict"

  # This widget is one of the main. It's a classical dynamic selector
  $.widget "ui.selector",
    options:
      clear: false

    id: null

    _create: ->
      @lastSearch = @element.val()
      if @element.parent().is('.selector')
        parent = @element.parent()
        @dropDownButton = parent.find('.selector-dropdown[rel="dropdown"]').first()
        @dropDownMenu = parent.find('.selector-choices-list').first()
        @valueField = parent.find('.selector-value').first()
      else
        @element.wrap $("<div>", class: "selector")

        @element.attr "autocomplete", "off"
        @element.addClass('selector-search')

        # Create drop down button
        @dropDownButton = $ "<a>",
            href: "##{@element.attr('id')}"
            rel: 'dropdown'
            tabindex: -1
            class: 'selector-dropdown btn btn-default dropdown-toggle sr-only'
          .insertAfter @element

        # Create drop down menu
        @dropDownMenu = $ "<div>",
            class: "items-menu selector-choices-list"
          .hide()
          .insertAfter(@element)

        # Create value field if it doesn't exist
        if @element.data("valueField")?
          @valueField = $ @element.data("valueField")
        else
          @valueField = $ "<input>",
            type: "hidden"
            name: @element.attr('name')
            class: 'selector-value'
            'data-parameter-name': @element.attr('data-value-parameter-name')
          @element.after @valueField
        @element.removeAttr "name"
        if @element.attr("required") is "true"
          @valueField.attr "required", "true"
        unless @valueField.val()? and @valueField.val() != ''
          @valueField.attr("value", @element.val())
      this._on @element,
        keypress: "_keypress"
        keyup: "_keyup"
#        focusout: "_focusOut"
      this._on @dropDownButton,
        click: "_buttonClick"
#        focusout: "_focusOut"
      this._on @dropDownMenu,
        "click ul li.item": "_menuItemClick"
        "mouseenter ul li.item": "_menuMouseEnter"
        "click .item-footer": "_actionFooterItemClick"

      $(document).on 'mousedown',(e) =>
        if $(e.target).hasClass('items-list') or $(e.target).hasClass('selector-dropdown')
          e.stopPropagation()
        else
          @_focusOut(e)

      @initializing = true
      if @valueField.val()? and @valueField.val().length > 0
        this._set @valueField.val(), true
      else if @element.val()? and @element.val().length > 0
        this._set @element.val(), true
      else
        @initializing = false
      @element.prop("widgetInitialized", true)

    value: (newValue) ->
      if newValue is null or newValue is undefined or newValue is ""
        val = parseInt(@valueField.val())
        val = null if isNaN(val)
        return val
      this._set(newValue)

    _set: (id, triggerEvents = false) ->
      if id is null or id is undefined or id is ""
        @initializing = false
        return @valueField.val()
      url = this.sourceURL()
      $.ajax
        url: url
        dataType: "json"
        data:
          id: id
        success: (data, status, request) =>
          listItem = $.parseJSON(request.responseText)[0]
          if listItem?
            @_select listItem.id, listItem.label, triggerEvents
          else
            console.warn "JSON cannot be parsed. Get: #{request.responseText}."
        error: (request, status, error) ->
          alert "Cannot get details of item on #{url} (#{request.status}/#{request.readyState}/#{request.statusCode()}) (#{status}): #{error}"
      this

    url: (newURL) ->
      if newURL is null or newURL is undefined or newURL is ""
        @element.attr("data-selector")
      else
        @element.attr("data-selector", newURL)

    sourceURL: (newURL) ->
      if newURL is null or newURL is undefined or newURL is ""
        @element.attr("data-selector")
      else
        @element.attr("data-selector", newURL)

    clear: ->
      @element.val('')
      @valueField.val('')

    # Check that current selection is valid
    # If autoselect, autoselect first record if empty
    check: (autoselect = false) ->
      id = @valueField.val()
      if id is null or id is undefined or id is ""
        @autoselect()
      else
        $.ajax
          url: @sourceURL()
          dataType: "json"
          data:
            ids: [id]
          success: (data, status, request) =>
            if data.length <= 0
              @autoselect()
          error: (request, status, error) ->
            console.error "Cannot get details of item on #{url} (#{request.status}/#{request.readyState}/#{request.statusCode()}) (#{status}): #{error}"
      this


    # Select first record if exist
    autoselect: ->
      $.ajax
        url: @sourceURL()
        dataType: "json"
        data:
          limit: 1
        success: (data, status, request) =>
          if data? and data[0]?
            @_set(data[0].id, true)
          else
            @clear()
        error: (request, status, error) ->
          console.error "Cannot get details of item on #{url} (#{request.status}/#{request.readyState}/#{request.statusCode()}) (#{status}): #{error}"

    _select: (id, label, triggerEvents = false, selectedElement = null) ->
      @lastSearch = label
      len = 4 * Math.round(Math.round(1.11 * label.length) / 4)
      @element.attr "size", (if len < 20 then 20 else (if len > 80 then 80 else len))
      @element.val label
      @valueField.prop "itemLabel", label
      @valueField.val id
      @id = parseInt id
      if @dropDownMenu.is(":visible")
        @dropDownMenu.hide()
      unless $(document).data('editedMode')
        if triggerEvents is true
          @valueField.trigger "selector:change"
          @element.trigger "selector:change", selectedElement
        if @initializing
          @valueField.trigger "selector:initialized"
          @element.trigger "selector:initialized"
          @initializing = false
        @valueField.trigger "selector:set"
        @element.trigger "selector:set"
      $(document).data('editedMode', false)

      if (redirect = @element.data("redirect-on-change-url")) && (param = @element.attr('id')) && id
        if @element.closest('form').data('dialog') is undefined
          window.location = redirect + "?" + param + "="+ id
        else
          dialog = $("##{@element.closest('form').data('dialog')}")

          returns = dialog.prop('dialogSettings').returns || returns:
            success: (frame, data, status, request) ->
              frame.dialog "close"
              return

            invalid: (frame, data, status, request) ->
              frame.html request.responseText
              return

          # open it in a new dialog
          url = redirect + "?" + param + "="+ id
          E.dialog.open url,
            returns: returns,
            inherit: @element.closest('form').data('dialog')

      this

    _openMenu: (search) ->
      data = {}
      if search?
        data.q = search
      if @element.data("selector-new-item")
        data.insert = 1
      if @element.data("with")
        $(@element.data("with")).each ->
          paramName = $(this).data("parameter-name") || $(this).attr("name") || $(this).attr("id")
          if paramName?
            data[paramName] = $(this).val() || $.trim($(this).html())
      menu = @dropDownMenu
      url = this.sourceURL()
      $.ajax
        url: url
        dataType: "html"
        data: data
        success: (data, status, request) =>
          menu.html data
          if data.length > 0
            menu.show()
            @element.trigger('selector:menu-opened')
          else
            menu.hide()
        error: (request, status, error) ->
          alert "Selector failure on #{url} (#{status}): #{error}"

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
      @element.trigger('selector:menu-closed')
      true

    _choose: (selected) ->
      # console.log "choose"
      selected ?= @dropDownMenu.find("ul li.item.selected").first()
      if selected.length > 0
        if selected.is("[data-item-label][data-item-id]")
          this._select(selected.data("item-id"), selected.data("item-label"), true, selected)
        else if selected.is("[data-new-item]")
          parameters = {}
          if selected.data("new-item").length > 0
            parameters.name = selected.data("new-item")
          E.dialog.open @element.data("selector-new-item"),
            data: parameters
            returns:
              success: (frame, data, status, request) =>
                @_set(request.getResponseHeader("X-Saved-Record-Id"), true)
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
        if @searchRequestTimeout?
          window.clearTimeout(@searchRequestTimeout)
        @searchRequestTimeout = window.setTimeout(
          () =>
            if search.length > 0
              @_openMenu search
            else
              @dropDownMenu.hide()
          , 500)
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
      setTimeout =>
        @_closeMenu()
      , 300
      true

    _buttonClick: (event) ->
      if @dropDownMenu.is(":visible")
        @dropDownMenu.hide()
      else if !@element.is(":disabled")
        this._openMenu()
      false

    _menuItemClick: (event) ->
      # console.log "menuclick"
      # console.log event.target
      this._choose()
      false

    _actionFooterItemClick: (event) ->
      this._choose($(event.target))
      false

    _menuMouseEnter: (event) ->
      item = $(event.target)
      item.closest("ul").find("li.item.selected").removeClass "selected"
      item.addClass "selected"
      false

  $(document).behave "load", "input[data-selector]", (event) ->
    $("input[data-selector]").each ->
      $(this).selector()

  $(document).on "selector:change", (changeEvent, value) ->
      $("*[data-selector-update]").each ->
        updateSource = $(this)
          .closest($(this).data("selector-use-closest"))
          .find("*[data-selector-id='"+$(this).data("selector-update")+"']")[0]
        if updateSource == changeEvent.target
          if value
            $(this).html $(value).data("item-"+$(this).data("selector-update-with"))
  return
) ekylibre, jQuery
