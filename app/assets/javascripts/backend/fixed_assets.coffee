((E, $) ->
  'use strict'

  $(document).ready ->
    $("a.state-bar__state[data-name='fixed_asset_sold']").on 'click', (event) ->
      return if $('#selling-actions-modal').data('sale-id')
      event.preventDefault()
      event.stopPropagation()
      $('#selling-actions-modal').modal('show')

    $('#submit-form').on 'click', (event) ->
      $('#selling-actions-modal').find('form').submit() if $('select#fixed_asset_sale_item_id').val()

    $('select#fixed_asset_sale_item_id').on 'change', (event) ->
      $('#selling-actions-modal').find('#submit-form').prop('disabled', !!!$('select#fixed_asset_sale_item_id').val())


  $(document).on 'change', "input[type='checkbox'][data-show='#assets']", (event) ->
    $quantityInput = $(this).closest('.nested-fields').find("input[data-trade-component='quantity']")
    if $(this).is(':checked')
      $quantityInput.prop('disabled', true)
      $quantityInput.val(1)
      $quantityInput.trigger('change')
    else
      $quantityInput.prop('disabled', false)



) ekylibre, jQuery
