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


) ekylibre, jQuery
