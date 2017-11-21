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

    $(document).on 'selector:change', '.invoice-variant.selector-search', (event) ->
      E.PurchaseInvoices.fillStocksCounters(event)

    $(document).on 'change', '.nested-fields .form-field .purchase_invoice_items_quantity .invoice-quantity', (event) ->
      E.PurchaseInvoices.fillStocksCounters(event)

    $(document).on 'keyup', '.nested-fields .form-field .purchase_invoice_items_quantity .invoice-quantity', (event) ->
      E.PurchaseInvoices.fillStocksCounters(event)

    $('#new_purchase_invoice table.list').on 'cocoon:after-insert', (event, insertedItem) ->
      new_id = new Date().getTime()
      if typeof insertedItem != 'undefined'
        insertedItem.attr('id', "new_reception_#{new_id}")

        $(insertedItem).find('input, select').each ->
          elementNewId = $(this).attr('id').replace(/[0-9]+/, new_id)
          elementNewName = $(this).attr('name').replace(/[0-9]+/, new_id)
          $(this).attr('id', elementNewId)
          $(this).attr('name', elementNewName)

        element = $(insertedItem).find('#purchase_invoice_items_attributes_RECORD_ID_parcels_purchase_invoice_items')
        newName = element.attr('name').replace('RECORD_ID', new_id)
        newId = element.attr('id').replace('RECORD_ID', new_id)

        $(element).attr('id', newId)
        $(element).attr('name', newName)


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
