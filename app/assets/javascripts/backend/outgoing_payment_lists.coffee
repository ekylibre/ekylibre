((E, $, C) ->
  'use strict'

  $(document).on "change", "*[data-outgoing-payment-purchase-affair-selector]", (e) ->

    $el = $(e.currentTarget)
    $parent = $el.closest('[data-outgoing-payment-purchase-affair]')
    $target = $parent.find('[data-outgoing-payment-purchase-affair-selection]')
    amount = $parent.find('[data-outgoing-payment-purchase-affair-amount]').data('outgoing-payment-purchase-affair-amount')

    if $el.prop('checked')
      $target.val $parent.data('outgoing-payment-purchase-affair')
      $el.data('outgoing-payment-selected-amount', amount)
    else
      $target.val ''
      $el.data('outgoing-payment-selected-amount', 0)

    # recalculate items for current third
    $third = $el.closest('[data-outgoing-payment-third]')
    $affairs = $third.find('[data-outgoing-payment-selected-amount]')
    $total = $third.find('[data-outgoing-payment-total]')
    $total.removeClass('error')

    total = 0.0
    $affairs.each () ->
      total += parseFloat $(this).data('outgoing-payment-selected-amount')

    $total.text C.toCurrency(total.toFixed(2))

    if total < 0
      $total.addClass('error')


  $(document).on "click", "[data-outgoing-payment-third] thead ", (e) ->
    $(e.currentTarget).siblings('tbody').toggle()
    return false

  return
) ekylibre, jQuery, calcul
