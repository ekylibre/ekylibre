((E, $) ->
  'use strict'

  $(document).ready ->
    $(document).on 'click', '.btn[data-validate="item-form"]', (event) ->
      totalAmountExcludingTaxes = 0
      totalVatRate = 0
      totalAmountIncludingTaxes = 0

      $('.nested-fields .item-display').map (index, item) =>
        amountExcludingTaxes = $(item).find('.total-column label.amount-excluding-taxes').text()
        vatRate = $(item).find('.total-column label.vat-rate').text().split("%")[0]

        totalAmountExcludingTaxes += parseFloat(amountExcludingTaxes)
        totalAmountIncludingTaxes += parseInt(amountExcludingTaxes * (1 + (parseFloat(vatRate) / 100)))
        totalVatRate += parseFloat(parseFloat(totalAmountIncludingTaxes - totalAmountExcludingTaxes).toFixed(2))
        $('.nested-item-form').each (index, item) ->

      $('.invoice-totals .total-except-tax .total-value').text(totalAmountExcludingTaxes)
      $('.invoice-totals .vat-total .total-value').text(totalVatRate)
      $('.invoice-totals .invoice-total .total-value').text(totalAmountIncludingTaxes)

) ekylibre, jQuery
