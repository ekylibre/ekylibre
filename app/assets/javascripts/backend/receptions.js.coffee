(($) ->
  'use strict'

  $(document).ready ->
    $('input[data-warn-if-checked]').behave 'load', ->
      $('input[data-warn-if-checked]').each ->
        input = $(this)
        container = input.closest('.non-compliant')
        if container.find('.warn-message').length is 0
          container.prepend($('<span class="warn-message"></span>').html(input.data('warn-if-checked')).hide())
        input.click ->
          if input.prop('checked')
            container.find('.warn-message').show()
          else
            container.find('.warn-message').hide()

    $('h2[data-warn-if-checked]').behave 'load', ->
      $('h2[data-warn-if-checked]').each ->
        h2 = $(this)
        h2.html(h2.data('warn-if-checked'))
        $('input[data-warn-if-checked]').click ->
          if $('input[data-warn-if-checked]:checked:visible').length >= 1
            h2.show()
          else
            h2.hide()


) jQuery
