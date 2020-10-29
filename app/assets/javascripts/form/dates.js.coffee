((E, $) ->
  # Watch for element insertion via javascript
  E.onDOMElementAdded
    "input[type='date']": ($element) => $element.each -> E.forms.date.enableDatePicker @
    "input[type='datetime']": ($element) => $element.each -> E.forms.date.enableDatetimePicker @
    "input[type='daterange']": ($element) => $element.each -> E.forms.date.enableDateRangePicker @

  # Initializes date fields
  $(document).ready =>
    $("input[type='date']").each -> E.forms.date.enableDatePicker @
    $("input[type='datetime']").each -> E.forms.date.enableDatetimePicker @
    $("input[type='daterange']").each -> E.forms.date.enableDateRangePicker @

) ekylibre, jQuery
