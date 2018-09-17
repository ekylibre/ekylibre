((E, $) ->
  'use strict'

  $(document).on 'change', '#ledger', (e) ->
    form = $(@).closest("form")
    form.submit()

  $(document).ready ->
    $('input[data-mask-lettered-items]').each ->
      E.ledgers.toggleLetteredItemsVisibility.call($(this))

    $('input[data-mask-lettered-items]').on 'change', (e) ->
      E.ledgers.toggleLetteredItemsVisibility.call($(this))

    $('input[data-mask-draft-items]').each ->
      E.ledgers.toggleDraftItemsVisibility.call($(this))

    $('input[data-mask-draft-items]').on 'change', (e) ->
      E.ledgers.toggleDraftItemsVisibility.call($(this))

  E.ledgers =
    toggleLetteredItemsVisibility: ->
      $input = $(this)
      $list = $($input.data('mask-lettered-items'))
      $letteredItems = $list.find('.lettered-item')
      $letteredItems.toggle !$input.is(':checked')

      $.ajax
        url: $input.data('preference-url')
        type: 'PATCH'
        data:
          masked: $input.is(':checked') ? 'true' : 'false'

    toggleDraftItemsVisibility: ->
      $input = $(this)
      $list = $($input.data('mask-draft-items'))
      $letteredItems = $list.find('.draft-item')
      $letteredItems.toggle !$input.is(':checked')

      $.ajax
        url: $input.data('preference-url')
        type: 'PATCH'
        data:
          masked: $input.is(':checked') ? 'true' : 'false'
) ekylibre, jQuery
