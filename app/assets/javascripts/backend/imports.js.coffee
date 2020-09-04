((E, $) ->
  'use strict'

  E.refresh =
    filter: '*[data-refresh-after][data-url]'
    delay: 4

    run: () ->
      element = $(this)
      signatureDetails = $('span.signature-trigger').length
      $.ajax
        url: element.data('url') + "?archives=#{signatureDetails}"
        success: (data, status, request) =>
          element.replaceWith(data)

    all: () ->
      $(E.refresh.filter).each () ->
        E.refresh.run.call(this)

  $(document).ready ->
    window.clearInterval(E.refresh.interval)
    E.refresh.interval = window.setInterval(E.refresh.all, E.refresh.delay * 1000)

  $(document).on 'change', 'select#import_nature', (event) ->
    $(this).closest('form').find('.import-file-upload').toggle(!!$(this).val())

  $(document).on 'click', 'button.btn[data-hide-content]', (e) ->
    e.preventDefault()
    $selector = $(this).closest('form').find($(this).data('hide-content'))
    $selector.hide()
    $(this).closest('form').find('select#import_nature').prop('selectedIndex', 0)

) ekylibre, jQuery
