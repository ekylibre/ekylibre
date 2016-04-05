((E, $) ->
  'use strict'

  $(document).on 'click', '*[data-import]', ->
    button = $(this)
    file_field = $(button.data('import'))
    file_field.on 'change', ->
      if button.data('disable-with')?
        button.attr('disabled', 'disabled')
        button.html(button.data('disable-with'))
      form = file_field.closest('form')
      form.find('input[name="format"]').attr('value', button.data('import-format'))
      form.submit()
    file_field.click()
    return false

) ekylibre, jQuery
