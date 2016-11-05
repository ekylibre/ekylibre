(($) ->

  unless Modernizr.touch and Modernizr.inputtypes.date

    # Initializes date fields
    $(document).on "focusin click keyup change", "input[type='date']", (event) ->
      element = $(this)
      if element.attr("autocomplete") isnt "off"
        locale = element.attr("lang")
        options = {}
        $.extend options, $.datepicker.regional[locale],
          dateFormat: "yy-mm-dd"
        element.datepicker options
        element.attr "autocomplete", "off"
      return

    # Initializes datetime fields
    $(document).on "focusin click keyup change", "input[type='datetime']", (event) ->
      element = $(this)
      if element.attr("autocomplete") isnt "off"
        locale = element.attr("lang")
        element.datetimepicker
          format: "YYYY-MM-DD HH:mm"
          locale: locale
          sideBySide: true
          icons:
            time: 'icon icon-time'
            date: 'icon icon-calendar'
            up: 'icon icon-chevron-up'
            down: 'icon icon-chevron-down'
            previous: 'icon icon-chevron-left'
            next: 'icon icon-chevron-right'
            today: 'icon icon-screenshot'
            clear: 'icon icon-trash'
            close: 'icon icon-remove'
          showClear: true
          showClose: true
          showTodayButton: true
        element.attr "autocomplete", "off"
      return

  return
) jQuery
