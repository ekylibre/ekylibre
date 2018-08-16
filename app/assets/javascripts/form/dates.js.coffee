(($) ->

  unless Modernizr.touch and Modernizr.inputtypes.date

    # Initializes date fields
    $(document).on "focusin click keyup change", "input[type='date']", (event) ->
      element = $(this)
      if element.attr("autocomplete") isnt "off"
        locale = element.attr("lang") or I18n.locale.slice(0, 2) # until we get corresponding locale codes
        options = {}
        $.extend options, $.datepicker.regional[locale],
          dateFormat: "yy-mm-dd"
          maxDate: element.data('max-date')
        element.datepicker options
        element.attr "autocomplete", "off"
      return

    $(document).on "focusin click keyup change", "input[type='daterange']", (event) ->
      element = $(this)
      if element.attr("autocomplete") isnt "off"
        element.attr("lang")
        locale = element.attr("lang") or I18n.locale.slice(0, 2) # until we get corresponding locale codes
        options = {}
        $.extend options,
          format: "YYYY-MM-DD"
          language: locale
          showShortcuts: false
          showTopbar: false
          separator: ' – '
        element.dateRangePicker options
        element.attr "autocomplete", "off"
      return

    # Initializes datetime fields
    $(document).on "focusin click keyup change", "input[type='datetime']", (event) ->
      element = $(this)
      if element.attr("autocomplete") isnt "off"
        locale = element.attr("lang") or I18n.locale.slice(0, 2) # until we get corresponding locale codes
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
          tooltips:
            selectMonth:  I18n.translate('date.dateTooltipFormats.selectMonth')
            incrementHour: I18n.translate('date.dateTooltipFormats.incrementHour')
            incrementMinute: I18n.translate('date.dateTooltipFormats.incrementMinute')
            decrementHour: I18n.translate('date.dateTooltipFormats.decrementHour')
            decrementMinute: I18n.translate('date.dateTooltipFormats.decrementMinute')
          showClear: true
          showClose: true
          showTodayButton: true
          widgetPositioning:
            horizontal: 'auto'
            vertical: 'bottom'
        element.attr "autocomplete", "off"
      return

  return
) jQuery
