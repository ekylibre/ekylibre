
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
          # Back to month
          x *= 12 if period == "year"
          # Back to wanted duration
          x /= 12 if input.val() == "year"
          duration.val(x.toFixed(0))
    form.prop("lastRepaymentPeriod", input.val())

  return
) ekylibre, jQuery
