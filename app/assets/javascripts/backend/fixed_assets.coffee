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


  $(document).on 'change', "input[type='checkbox'][data-show='#assets']", (event) ->
    $quantityInput = $(this).closest('.nested-fields').find("input[data-trade-component='quantity']")
    if $(this).is(':checked')
      $quantityInput.prop('disabled', true)
      $quantityInput.val(1)
      $quantityInput.trigger('change')
    else
      $quantityInput.prop('disabled', false)



) ekylibre, jQuery
