((E, $) ->
  # Options
  baseDateOptions = ($element) => $.extend {},
    locale: getLocale($element)
    dateFormat: 'Y-m-d'
    altInput: true
    allowInput: true
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

  setupBlurListener = ($element, flatInstance) =>
    input = flatInstance.altInput
    input.addEventListener 'blur', (e) =>
      flatInstance.setDate(input.value, true, flatInstance.config.altFormat)

  enableDatePicker = (element) =>
    $element = $(element)
    return if $element.is('[data-flatpickr="false"]')
    options = baseDateOptions $element
    flatInstance = $element
      .flatpickr options
    setupBlurListener $element, flatInstance

  enableDatetimePicker = (element) =>
    $element = $(element)
    options = baseDateTimeOptions $element
    flatInstance = $element
      .flatpickr options
    setupBlurListener $element, flatInstance

  enableDateRangePicker = (element) =>
    $element = $(element)
    options = baseDateRangeOptions $element
    flatInstance = $element
      .attr 'type', 'text'
      .flatpickr options
    setupBlurListener $element, flatInstance

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
