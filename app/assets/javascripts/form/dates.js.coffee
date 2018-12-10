(($) ->

  unless Modernizr.touch

    # Initializes date fields
    $(document).ready ->
      $.datepicker.regional['fr'].dateFormat = 'dd-mm-yy'

      $("input[type='date']").each ->
        $(this).attr('type', 'text')
        $(this).addClass('text-datepicker')

      $("input[type='datetime']").each ->
        $(this).attr('type', 'text')
        $(this).addClass('text-datetimepicker')

      $("input[type='daterange']").each ->
        $(this).attr('type', 'text')
        $(this).addClass('text-daterangepicker')

      $(document).on "focusin click keyup change", "input[type='text'].text-datepicker", (event) ->
        element = $(this)
        if element.attr("autocomplete") isnt "off"
          locale = element.attr("lang") or I18n.locale.slice(0, 2) # until we get corresponding locale codes
          options = { dateFormat: "dd-mm-yy" }
          $.extend options, $.datepicker.regional[locale],
            maxDate: element.data('max-date')
          element.datepicker options
          element.attr "autocomplete", "off"
        return

      $(document).on "focusin click keyup change", "input[type='text'].text-daterangepicker", (event) ->
        element = $(this)
        if element.attr("autocomplete") isnt "off"
          element.attr("lang")
          locale = element.attr("lang") or I18n.locale.slice(0, 2) # until we get corresponding locale codes
          dateFormat = $.datepicker.regional[locale].dateFormat.toUpperCase().replace("YY", "YYYY")
          options = {}
          $.extend options,
            format: "#{dateFormat}"
            language: locale
            showShortcuts: false
            showTopbar: false
            separator: ' – '
          element.dateRangePicker options
          element.attr "autocomplete", "off"
        return

      # Initializes datetime fields
      $(document).on "focusin click keyup change", "input[type='text'].text-datetimepicker", (event) ->
        element = $(this)
        if element.attr("autocomplete") isnt "off"
          locale = element.attr("lang") or I18n.locale.slice(0, 2)
          dateFormat = $.datepicker.regional[locale].dateFormat.toUpperCase().replace("YY", "YYYY")
          element.datetimepicker
            format: "#{dateFormat} HH:mm"
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
