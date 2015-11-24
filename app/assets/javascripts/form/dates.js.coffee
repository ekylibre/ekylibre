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
          format: "yyyy-mm-dd hh:ii"
          language: locale
          autoclose: true
          minuteStep: 5
          todayBtn: true
        element.attr "autocomplete", "off"
      return

  return
) jQuery
