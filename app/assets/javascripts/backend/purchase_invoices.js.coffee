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
        totalVatRate += parseFloat(vatRate)
        totalAmountIncludingTaxes += parseInt(amountExcludingTaxes * (1 + (vatRate / 100)))
        $('.nested-item-form').each (index, item) ->

      $('.invoice-totals .total-except-tax .total-value').text(totalAmountExcludingTaxes)
      $('.invoice-totals .vat-total .total-value').text(totalVatRate)
      $('.invoice-totals .invoice-total .total-value').text(totalAmountIncludingTaxes)

    $(document).on 'selector:change', '.invoice-variant.selector-search', (event) ->
      E.PurchaseInvoices.fillStocksCounters(event)

    $(document).on 'change', '.nested-fields .form-field .purchase_invoice_items_quantity .invoice-quantity', (event) ->
      E.PurchaseInvoices.fillStocksCounters(event)

    $(document).on 'keyup', '.nested-fields .form-field .purchase_invoice_items_quantity .invoice-quantity', (event) ->
      E.PurchaseInvoices.fillStocksCounters(event)


  E.PurchaseInvoices =
    fillStocksCounters: (event) ->
      currentForm = $(event.target).closest('.nested-item-form')
      variantId = $(currentForm).find('.purchase_invoice_items_variant .selector-value').val()

      if variantId == ""
        return

      $.ajax
        url: "/backend/product_nature_variants/#{variantId}/detail",
        success: (data, status, request) ->
          $(currentForm).find('.merchandise-current-stock .stock-value').text(data.stock)
          $(currentForm).find('.merchandise-current-stock .stock-unit').text(data.unit.name)

          quantity = 0
          quantityElement = $(currentForm).find('.purchase_invoice_items_quantity .invoice-quantity')

          if ($(quantityElement).val() != "")
            quantity = $(quantityElement).val()

          newStock = parseFloat(data.stock) - parseFloat(quantity)
          $(currentForm).find('.merchandise-stock-after-invoice .stock-value').text(newStock)
          $(currentForm).find('.merchandise-stock-after-invoice .stock-unit').text(data.unit.name)

) ekylibre, jQuery
