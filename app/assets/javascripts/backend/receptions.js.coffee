(($) ->
  'use strict'

  $(document).ready ->
    $('input[data-warn-if-checked]').each ->
      input = $(this)
      if input.parent().find('.warn-message').length is 0
        input.parent().append($('<span class="warn-message"></span>').html(input.data('warn-if-checked')).hide())
      input.click ->
        if input.prop('checked')
          $('.warn-message').show()
        else
          $('.warn-message').hide()

) jQuery
