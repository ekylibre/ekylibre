((E, $) ->
  "use strict"

  E.dialog =
    count: 0

    open: (url, settings) ->
      frame_id = "dialog-#{E.dialog.count}"

      if settings.inherit?
        frame_id = settings.inherit

      width = $(document).width()
      defaultSettings =
        header: "X-Return-Code"
        width: 0.6
        height: 'auto'

      settings = {}  if settings is null or settings is `undefined`
      settings = $.extend({}, defaultSettings, settings)
      data = settings.data or {}
      data.dialog = frame_id
      $.ajax url,
        data: data
        success: (data, status, request) ->

          if $("##{frame_id}").length
            frame = $("##{frame_id}")
          else
            frame = $(document.createElement("div"))
            $("body").append frame

          width = undefined
          height = undefined
          frame.attr
            id: frame_id
            class: "dialog ajax-dialog"
            style: "display:none;"

          frame.html data
          frame.prop "dialogSettings", settings
          if settings.width is 0
            width = "auto"
          else if settings.width < 1
            width = $(window).width() * settings.width
          else
            width = settings.width
          if settings.height is 0
            height = "auto"
          else if settings.height < 1
            height = $(window).height() * settings.height
          else
            height = settings.height

          if frame.is(':ui-dialog')

            #Ensure dialog content is visible
            frame.addClass 'ui-dialog-content'

          frame.dialog
            autoOpen: false
            show: "fade"
            modal: true
            width: width
            maxHeight: height

          E.dialog.initialize frame
          frame.dialog "open"

          frame.trigger('dialog:show')

          $("##{frame_id}").on 'selector:menu-opened', (e) ->
            $el = $(this).find('.form-fields')
            pad = parseInt($el.css('padding-top').replace('px','')) + parseInt($el.css('padding-bottom').replace('px',''))
            $el.height($el[0].scrollHeight-pad) if $el[0].scrollHeight > $el.height() + pad

          $("##{frame_id}").on 'selector:menu-closed', (e) ->
            $(this).find('.form-fields').height('auto')

          return

        error: (request, status, error) ->
          E.ajaxErrorHandler(request, status, error)
          frame = $("##{frame_id}")
          frame.dialog "close"
          frame.remove()
          return

      E.dialog.count += 1
      return

    initialize: (frame) ->
      frame_id = frame.attr("id")
      title = frame.prop("dialogSettings").title
      heading = undefined
      if title is null or title is `undefined`
        heading = $("##{frame_id} h1")
        if heading[0] isnt null and heading[0] isnt `undefined`
          title = heading.text()
          heading.remove()
      frame.dialog "option", "title", title
      $("##{frame_id} form").each (index, form) ->
        $(form).attr "data-dialog", frame_id
        return

    submit: ->
      form = $(this)
      frame_id = form.attr("data-dialog")
      frame = $("##{frame_id}")
      settings = frame.prop("dialogSettings")
      field = $(document.createElement("input"))
      field.attr
        type: "hidden"
        name: "dialog"
        value: frame_id

      form.append field
      $.ajax form.attr("action"),
        type: form.attr("method") || "POST"
        data: form.serialize()
        success: (data, status, request) ->
          returnCode = request.getResponseHeader(settings.header)
          returns = settings.returns
          unknownReturnCode = true
          for code of returns
            if returns.hasOwnProperty(code) and returnCode is code and $.isFunction(returns[code])
              returns[code].call form, frame, data, status, request
              unknownReturnCode = false
              # no need to force triggering. If needed, call it in returns.
#              E.dialog.initialize frame
#              frame.trigger('dialog:show')
              break
          if unknownReturnCode
            if $.isFunction(settings.defaultReturn)
              settings.defaultReturn.call form, frame, data, status, request
            else
              console.error "FAILURE (Unknown return code for header #{settings.header}): #{returnCode}"
              alert "FAILURE (Unknown return code for header #{settings.header}): #{returnCode}"
          return

        error: (request, status, error) ->
          E.ajaxErrorHandler(request, status, error)
          frame = $("##{frame_id}")
          frame.dialog "close"
          frame.remove()
          return

      # if ($.isFunction(settings.error)) { settings.error.call(form, frame, request, status, error); }
      false


  # Submits dialog forms
  $(document).on "submit", ".ajax-dialog form[data-dialog]", E.dialog.submit


  # Opens a dialog for a resource creation
  $(document).on "click", "a[data-add-item]", ->
    element = $(this)
    list_id = element.data('add-item')
    list = $(list_id)
    url = element.attr("href")
    E.dialog.open url,
      returns:
        success: (frame, data, status, request) ->
          record_id = request.getResponseHeader("X-Saved-Record-Id")
          if list[0] isnt `undefined`
            $.ajax list.attr("data-refresh"),
              data:
                selected: record_id

              success: (data, status, request) ->
                list.replaceWith request.responseText
                $("#{list_id} input").trigger "emulated:change"
                return
          else
            console.log "Cannot do anything in return"

          frame.dialog "close"
          return

        invalid: (frame, data, status, request) ->
          frame.html request.responseText
          return

  $(document).on 'dialog:show', '.dialog', ->
    if $('.modal').length
      $(this).parent().css('z-index', '1050')

) ekylibre, jQuery
