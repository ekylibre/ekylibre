((E, $) ->
  'use strict'

  E.Purchases =
    fillStocksCounters: (form) ->
      $currentForm = $(form)
      variantId = $currentForm.find('[data-variant-of-deal-item]').next('.selector-value').val()

      if variantId == "" || !variantId?
        return
      $.ajax
        url: "/backend/product_nature_variants/#{variantId}/detail",
        success: (data, status, request) ->
          $currentStock = $currentForm.find('.merchandise-current-stock')
          if $currentStock.length
            $currentStock.find('.stock-value').text(data.stock)
            $currentForm.find('.stock-unit').text(data.unit.name)

          $futureStock = $currentForm.find('.merchandise-stock-after-purchase')
          if $futureStock.length
            quantity = 0
            $quantityElement = $currentForm.find("[data-trade-component='quantity']")

            newStock = parseFloat(data.stock) + parseFloat($quantityElement.val())
            $futureStock.find('.stock-value').text(newStock.toFixed(2))
            $futureStock.find('.stock-unit').text(data.unit.name)

) ekylibre, jQuery
