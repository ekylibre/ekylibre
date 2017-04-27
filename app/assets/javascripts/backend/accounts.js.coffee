((E, $) ->
  'use strict'

  $(document).ready ->
    $('input[data-mask-lettered-items]').each ->
      console.log "Yeah"
      E.accounts.toggleLetteredItemsVisibility.call($(this))

    $('input[data-mask-lettered-items]').on 'change', (e) ->
      E.accounts.toggleLetteredItemsVisibility.call($(this))

  E.accounts =
    toggleLetteredItemsVisibility: ->
      input = $(this)
      list = $(input.data('mask-lettered-items'))
      list.toggleClass('mask-lettered-items', input.is(':checked'))
      $.ajax
        url: input.data('preference-url')
        type: 'PATCH'
        data:
          masked: input.is(':checked') ? 'true' : 'false'

) ekylibre, jQuery
