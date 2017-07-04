(($) ->
  'use strict'

  $(document).ready ->
    warning_message = $('#reception_late_delivery').data('warn-if-checked')
    $('#warn-message').hide()
    $('#warn-message').text(warning_message)
    $('input#reception_late_delivery').parent().append($('#warn-message'))
    $('#reception_late_delivery').click ->
      if $('#reception_late_delivery').prop('checked')
        $('#warn-message').show()
      else
        $('#warn-message').hide()      

) jQuery
