((E, $) ->
  'use strict'

  $(document).ready ->
    $(document).on 'click', '.btn[data-validate="item-form"]', (event) ->
      totalAmountExcludingTaxes = 0
      totalVatRate = 0
      totalAmountIncludingTaxes = 0

      $('.nested-fields.purchase-order-items .item-display').map (index, item) =>
        amountExcludingTaxes = $(item).find('.total-column label.amount-excluding-taxes').text()
        vatRate = $(item).find('.total-column label.vat-rate').text().split("%")[0]

        totalAmountExcludingTaxes += parseFloat(amountExcludingTaxes)
        totalAmountIncludingTaxes += parseInt(amountExcludingTaxes * (1 + (parseFloat(vatRate) / 100)))

        calculVatRate = parseFloat(parseFloat(amountExcludingTaxes) * parseFloat(vatRate) / 100).toFixed(2)
        totalVatRate += parseFloat(calculVatRate)

        selectedVatValue = $(item).parent().find('.nested-item-form select.vat-total option:selected').val()
        $(item).find('.vat-rate').attr('data-selected-value', selectedVatValue)

      $('.order-totals .total-except-tax .total-value').text(totalAmountExcludingTaxes)
      $('.order-totals .vat-total .total-value').text(totalVatRate)
      $('.order-totals .order-total .total-value').text(totalAmountIncludingTaxes)

    $('#new_purchase_order').on 'iceberg:validated', E.Purchases.compute_amount
    $('.edit_purchase_order').on 'iceberg:validated', E.Purchases.compute_amount
    $('#new_purchase_order').on 'cocoon:after-remove', E.Purchases.compute_amount
    $('.edit_purchase_order').on 'cocoon:after-remove', E.Purchases.compute_amount

    $(document).on 'click', '.nested-fields .edit-item[data-edit="item-form"]', (event) ->
      vatSelectedValue = $(event.target).closest('.nested-fields').find('.item-display .vat-rate').attr('data-selected-value')
      $(event.target).closest('.nested-fields').find('.nested-item-form:visible .vat-total').val(vatSelectedValue) unless vatSelectedValue == undefined

    $(document).on 'selector:change', 'input#purchase_invoice_supplier_id', ->
      supplier_id = $(this).parent().find('.selector-value').val()
      $.ajax
        url: "/backend/entities/#{supplier_id}.json",
        success: (data,status, request) ->
          $(document).find('#purchase_invoice_payment_delay').val(data.supplier_payment_delay)

) ekylibre, jQuery
