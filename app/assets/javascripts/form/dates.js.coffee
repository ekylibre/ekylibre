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
          showClear: true
          keepOpen: false
          showClose: true
          showTodayButton: true
          widgetPositioning:
            horizontal: 'auto'
            vertical: 'bottom'
        element.on 'dp.change', (ev) ->
          old_dt = ev.oldDate
          new_dt = moment(new Date(ev.currentTarget.value))
          if old_dt.minute() != new_dt.minute()
            element.datetimepicker('hide');
        element.attr "autocomplete", "off"


      return

  return
) jQuery
