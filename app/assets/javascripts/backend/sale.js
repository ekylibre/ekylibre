(function () {
  // Sets the time of the selected date if the
  function handleSelectDate() {
    const element = document.querySelector('#sale_invoiced_at')

    if (element) {
      const flatInstance = element._flatpickr

      if (flatInstance) {
        configureFlatpickr(element, flatInstance)
      }
    }
  }

  function configureFlatpickr(element, flatInstance) {
    let lastValue
    flatInstance.set('onOpen', function (selectedDates) {
      lastValue = selectedDates[0]
      if (lastValue != null) {
        lastValue = moment(lastValue)
      }
    })

    flatInstance.set('onValueUpdate', function (selectedDates, _dateStr, instance) {
      const selectedDate = moment(selectedDates[0])
      const now = moment()

      if (selectedDate.isSame(now, 'day')) {
        // If today is selected. We want:
        // if no last_value or last value is an other day, set the time to now
        // else, do nothing
        if (lastValue == null || !selectedDate.isSame(lastValue, 'day')) {
          instance.setDate(now.toDate(), false)
        }
      }

      lastValue = selectedDate
    })

  }

  document.addEventListener('DOMContentLoaded', handleSelectDate)
  document.addEventListener('page:load', handleSelectDate)
})()