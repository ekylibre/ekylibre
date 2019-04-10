((E, $) ->
# Options
  baseDateOptions = ($element) => $.extend {},
    locale: getLocale($element)
    dateFormat: 'Y-m-d'
    altInput: true
    altFormat: 'd-m-Y'
  baseDateTimeOptions = ($element) => $.extend {}, baseDateOptions($element),
    enableTime: true
    dateFormat: 'Y-m-d H:i'
    altFormat: 'd-m-Y H:i'
    time_24hr: true
    plugins: [new confirmDatePlugin({
      showAlways: true
    })]
  baseDateRangeOptions = ($element) => $.extend {}, baseDateOptions($element),
    mode: 'range'
    dateFormat: 'Y-m-d'
    showMonths: 2

  # Utility function
  getLocale = ($element) => $element.attr("lang") or I18n.locale.slice(0, 2) # until we get corresponding locale codes

  enableDatePicker = (element) =>
    $element = $(element)
    return if $element.is('[data-flatpickr="false"]')
    options = baseDateOptions $element
    $element
      .flatpickr options

  enableDatetimePicker = (element) =>
    $element = $(element)
    options = baseDateTimeOptions $element
    $element
      .flatpickr options

  enableDateRangePicker = (element) =>
    $element = $(element)
    options = baseDateRangeOptions $element
    $element
      .attr 'type', 'text'
      .flatpickr options

  # Watch for element insertion via javascript
  E.onDOMElementAdded
    "input[type='date']": ($element) => $element.each -> enableDatePicker @
    "input[type='datetime']": ($element) => $element.each -> enableDatetimePicker @
    "input[type='daterange']": ($element) => $element.each -> enableDateRangePicker @

  # Initializes date fields
  $(document).ready =>
    $("input[type='date']").each -> enableDatePicker @
    $("input[type='datetime']").each -> enableDatetimePicker @
    $("input[type='daterange']").each -> enableDateRangePicker @

) ekylibre, jQuery
