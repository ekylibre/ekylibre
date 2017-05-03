((E, $) ->
  'use strict'

  $(document).ready ->
    count = 0
    $('#accounting_date').click ->
      if count == 0
        $('#accounting_date').datepicker 'option', maxDate: new Date($.now())
        $('#accounting_date').datepicker 'show'
        count++
) ekylibre, jQuery
