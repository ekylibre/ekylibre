((E, $) ->
  'use strict'

  $(document).ready ->
    $("a.state-bar__state[data-name='fixed_asset_sold']").on 'click', (event) ->
      return if $('#selling-actions-modal').data('sale-id')
      event.preventDefault()
      event.stopPropagation()
      $('#selling-actions-modal').modal('show')

    $('#submit-form').on 'click', (event) ->
      $('#selling-actions-modal').find('form').submit()



) ekylibre, jQuery
