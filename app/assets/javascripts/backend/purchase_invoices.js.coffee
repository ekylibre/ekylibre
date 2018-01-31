((E, $) ->
  'use strict'

  $(document).ready ->
    $('.nested-fields.purchase-invoice-items').each (index, purchase_invoice) ->
      hiddenFieldToChange = $(purchase_invoice).find('input[name="purchase_invoice[items_attributes][RECORD_ID][parcels_purchase_invoice_items]"]')
      $(hiddenFieldToChange).attr('name', "purchase_invoice[items_attributes][#{ index }][parcels_purchase_invoice_items]")
      $(hiddenFieldToChange).attr('id', "purchase_invoice_items_attributes_#{ index }_parcels_purchase_invoice_items")

    $(document).on 'click', '.btn[data-validate="item-form"]', (event) ->
      totalAmountExcludingTaxes = 0
      totalVatRate = 0
      totalAmountIncludingTaxes = 0

      $('.nested-fields.purchase-invoice-items .item-display').map (index, item) =>
        amountExcludingTaxes = $(item).find('.pretax-amount-column label.amount-excluding-taxes').text()
        vatRate = $(item).find('.total-column label.vat-rate').text().split("%")[0]
        amountIncludingTaxes = $(item).find('.total-column label.amount-including-taxes').text()

        totalAmountExcludingTaxes += parseFloat(amountExcludingTaxes)
        totalAmountIncludingTaxes += parseFloat(parseFloat(amountIncludingTaxes).toFixed(2))

        calculVatRate = parseFloat(parseFloat(amountExcludingTaxes) * parseFloat(vatRate) / 100).toFixed(2)
        totalVatRate += parseFloat(calculVatRate)

        selectedVatValue = $(item).parent().find('.nested-item-form select.invoice-vat-total option:selected').val()
        $(item).find('.vat-rate').attr('data-selected-value', selectedVatValue)

      $('.invoice-totals .total-except-tax .total-value').text(totalAmountExcludingTaxes)
      $('.invoice-totals .vat-total .total-value').text(totalVatRate)
      $('.invoice-totals .invoice-total .total-value').text(totalAmountIncludingTaxes)


    $(document).on 'selector:change', '.invoice-variant.selector-search', (event) ->
      E.PurchaseInvoices.fillStocksCounters(event)

    $(document).on 'change', '.nested-fields .form-field .purchase_invoice_items_quantity .invoice-quantity', (event) ->
      E.PurchaseInvoices.fillStocksCounters(event)

    $(document).on 'keyup', '.nested-fields .form-field .purchase_invoice_items_quantity .invoice-quantity', (event) ->
      E.PurchaseInvoices.fillStocksCounters(event)

    $(document).on 'click', '.nested-fields .edit-item[data-edit="item-form"]', (event) ->
      vatSelectedValue = $(event.target).closest('.nested-fields').find('.item-display .vat-rate').attr('data-selected-value')
      $(event.target).closest('.nested-fields').find('.nested-item-form:visible .invoice-vat-total').val(vatSelectedValue)

    $('#new_purchase_invoice table.list, .edit_purchase_invoice table.list').on 'cocoon:after-insert', (event, insertedItem) ->
      new_id = new Date().getTime()
      if typeof insertedItem != 'undefined'
        insertedItem.attr('id', "new_reception_#{new_id}")

        $(insertedItem).find('input, select').each ->
          oldId = $(this).attr('id')
          if !!oldId
            elementNewId = oldId.replace(/[0-9]+/, new_id)
            $(this).attr('id', elementNewId)

          oldName = $(this).attr('name')
          if !!oldName
            elementNewName = oldName.replace(/[0-9]+/, new_id)
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
