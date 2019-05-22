((E, $) ->
  'use strict'

  E.Purchases =
    fillStocksCounters: (event) ->
      currentForm = $(event.target).closest('.nested-item-form')
      variantId = $(currentForm).find('[data-variant-of-deal-item]').next('.selector-value').val()

      if variantId == ""
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
          $(currentForm).find('.merchandise-stock-after-purchase .stock-value').text(newStock)
          $(currentForm).find('.merchandise-stock-after-purchase .stock-unit').text(data.unit.name)

) ekylibre, jQuery
