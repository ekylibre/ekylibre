
((E, $) ->
  'use strict'

  $(document).behave "load click", "form label input[name='loan[repayment_period]']:checked", ->
    input = $(this)
    form = input.closest('form')
    form.find(".add-on.period").html(input.closest('label').text())
    if form.prop("lastRepaymentPeriod")?
      period = form.prop("lastRepaymentPeriod")
      if period != input.val()
        form.find("input[name='loan[repayment_duration]'], input[name='loan[shift_duration]']").each ->
          duration = $(this)
          x = duration.val()

          if period == "month"
            x /= 12 if input.val() == "year"
            x /= 6 if input.val() == "semester"
            x /= 3 if input.val() == "trimester"

          if period == "year"
            x *= 12 if input.val() == "month"
            x *= 2 if input.val() == "semester"
            x *= 4 if input.val() == "trimester"

          if period == "semester"
            x *= 6 if input.val() == "month"
            x /= 2 if input.val() == "year"
            x *= 2 if input.val() == "trimester"

          if period == "trimester"
            x *= 3 if input.val() == "month"
            x /= 4 if input.val() == "year"
            x /= 2 if input.val() == "semester"

          duration.val(x.toFixed(0))
    form.prop("lastRepaymentPeriod", input.val())

  return
) ekylibre, jQuery
