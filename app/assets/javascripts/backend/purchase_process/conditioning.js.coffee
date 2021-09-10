((E, $) ->
  'use strict'

  addConditioningData = ($selector) ->
    filterId = $selector.selector('value')
    variantId = $selector.closest('.nested-item-form').find($selector.data('variant-selector')).first().selector('value')
    return unless filterId && variantId

    url = $selector.data('conditioning-data-url')
    $quantity = $selector.closest('.storing-calculation').find("[data-trade-component='quantity']")

    $.getJSON url, filter_id: filterId, variant_id: variantId, (data) ->
      $selector.data('coefficient', data.coefficient)
      $selector.attr('data-coefficient', data.coefficient)
      $selector.data('interpolate-data-attribute', data.unit_name)
      $selector.attr('data-interpolate-data-attribute', data.unit_name)
      $quantity.trigger('change')


  $(document).on 'selector:change', '[data-conditioning-data-url]', (e) ->
    addConditioningData $(this)

  $(document).on 'selector:change', '[data-variant-selector]', (e, _a, _b, options = {}) ->
    E.trade.updateValues($(this).closest('.nested-fields').find($(this).data('variant-selector')).first(), false) unless options.manuallyTriggered

) ekylibre, jQuery
