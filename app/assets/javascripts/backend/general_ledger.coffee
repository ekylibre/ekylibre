((E, $) ->
  'use strict'

  $(document).on 'change', '#ledger', (e) ->
    form = $(@).closest("form")
    form.submit()

  $(document).ready ->
    $('input[data-mask-lettered-items]').each ->
      E.ledgers.toggleLetteredItemsVisibility.call($(this))

    $('input[data-mask-lettered-items]').on 'change', (e) ->
      E.ledgers.toggleLetteredItemsVisibility.call($(this), true)

    $('input[data-mask-draft-items]').each ->
      E.ledgers.toggleDraftItemsVisibility.call($(this))

    $('input[data-mask-draft-items]').on 'change', (e) ->
      E.ledgers.toggleDraftItemsVisibility.call($(this), true)

  E.ledgers =
    toggleLetteredItemsVisibility:(changed) ->
      $input = $(this)
      $list = $($input.data('mask-lettered-items'))
      $letteredItems = $list.find('.lettered-item')
      $letteredItems.toggle !$input.is(':checked')

      $.ajax
        url: $input.data('preference-url')
        type: 'PATCH'
        data:
          masked: $input.is(':checked') ? 'true' : 'false'
        success: ->
          location.reload() if changed

    toggleDraftItemsVisibility: (changed) ->
      $input = $(this)
      $list = $($input.data('mask-draft-items'))
      $draftItems = $list.find('.draft-item')
      $draftItems.toggle !$input.is(':checked')

      $.ajax
        url: $input.data('preference-url')
        type: 'PATCH'
        data:
          masked: $input.is(':checked') ? 'true' : 'false'
        success: ->
          location.reload() if changed

) ekylibre, jQuery
