((E, $) ->
  'use strict'

  $(document).on "keydown", '.nested-item-form', (event) ->
    if event.which == 13
      event.preventDefault()

  E.Purchases =
    fillStocksCounters: (form) ->
      currentForm = $(form)
      variantId = $(currentForm).find('[data-variant-of-deal-item]').next('.selector-value').val()

      if variantId == "" || !variantId?
        return
      $.ajax
        url: "/backend/product_nature_variants/#{variantId}/detail",
        success: (data, status, request) ->
          $(currentForm).find('.merchandise-current-stock .stock-value').text(data.stock)
          $(currentForm).find('.merchandise-current-stock .stock-unit').text(data.unit.name)

          quantity = 0
          quantityElement = $(currentForm).find("[data-trade-component='quantity']")

          if ($(quantityElement).val() != "")
            quantity = $(quantityElement).val()

          newStock = parseFloat(data.stock) + parseFloat(quantity)
          $(currentForm).find('.merchandise-stock-after-purchase .stock-value').text(newStock.toFixed(2))
          $(currentForm).find('.merchandise-stock-after-purchase .stock-unit').text(data.unit.name)

) ekylibre, jQuery
