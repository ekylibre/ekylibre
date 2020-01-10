((E, $) ->
  'use strict'

  $(document).ready ->
    $('input[data-mask-lettered-items]').each ->
      E.accounts.toggleLetteredItemsVisibility.call($(this))

    $('input[data-mask-lettered-items]').on 'change', (e) ->
      E.accounts.toggleLetteredItemsVisibility.call($(this))

    $('input[data-refresh-lettered-items]').on 'change', (e) ->

      $input = $(this)
      $("#mark_journal_entry_items tbody").html("")

      $.ajax
        url: $input.data('refresh-list-url')
        type: 'GET'
        data:
          masked: $input.is(':checked') ? 'true' : 'false'
          period: $input.data('period')
          started_on: $input.data('started-on')
          stopped_on: $input.data('stopped-on')

  E.accounts =
    toggleLetteredItemsVisibility: ->
      $input = $(this)
      $list = $($input.data('mask-lettered-items'))
      $letteredItems = $list.find('.lettered-item')
      $letteredItems.toggle !$input.is(':checked')

      $.ajax
        url: $input.data('preference-url')
        type: 'PATCH'
        datatype: 'JS'
        data:
          masked: $input.is(':checked') ? 'true' : 'false'



) ekylibre, jQuery
