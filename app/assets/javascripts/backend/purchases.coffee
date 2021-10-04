((E, $) ->
  'use strict'

  updateStockAfterPurchase = ($form, newstock) =>
    $form.find(".merchandise-stock-after-purchase .stock-value").text(newstock.toFixed(2))

  onTotalQuantityChanged = ($input) =>
    $form = $input.closest('.nested-item-form')
    coefficient = $form.find('[data-coefficient]').data('coefficient')
    newQuantity = $input.val()
    currentstock = getCurrentStock($form)
    if !coefficient || newQuantity.length == 0
      newStock = currentstock
    else
      newStock = currentstock + parseFloat(newQuantity) * coefficient
    updateStockAfterPurchase($form, newStock)

  getCurrentStock = ($form) =>
    parseFloat($form.find('.merchandise-current-stock .stock-value').text())

  getVariantStock = (variantId) =>
    p = $.getJSON("/backend/product_nature_variants/#{variantId}/detail")
    p2 = p.then (data) =>
      {
        stock: data.default_unit_stock,
        unit: data.default_unit_name
      }

  onvariantChanged = ($variantSelector) =>
    $form = $variantSelector.closest('.nested-item-form')

    variantId = $variantSelector.selector('value')
    getVariantStock(variantId).then (data) =>
      $form.find(".merchandise-current-stock .stock-value").text(data.stock)
      $form.find(".stock-unit").text(data.unit)
      updateQuantity($form)

    updateQuantity = ($form) =>
      $quantity = $form.find('.order-quantity, .invoice-quantity')

      if $quantity.val() == "0" || $quantity.val() == ""
        $quantity.val(1)
      $quantity.trigger('change')


  $(document).on 'keyup change', '.nested-fields .form-field .purchase_order_items_conditioning_quantity .order-quantity', (event) ->
    onTotalQuantityChanged $(this)

  $(document).on 'selector:change', '.order-variant.selector-search', (event) ->
    onvariantChanged $(this)

  $(document).on 'selector:change', '.invoice-variant.selector-search', (event) ->
    onvariantChanged $(this)

  $.each ['purchase_order', 'purchase_invoice'], (i, purchase_att) ->

    $(document).on 'input unit-value:change', ".#{purchase_att}_items_unit_pretax_amount > .controls > .input-append > input", ->
      unit_amount = ($(this).val() / $(this).data().coeff).toFixed(1)
      $(this.closest('tr')).find(".#{purchase_att}_items_base_unit_amount > .controls > .input-append > input").val unit_amount

    $(document).on 'selector:change', ".#{purchase_att}_items_variant > .controls > .selector > .selector-value", ->
      that = this;
      $.ajax '/backend/default_conditioning_unit',
        type: 'get'
        dataType: 'json'
        data: 'id': @value
        success: (data) ->
          element = $(that.closest('tr')).find(".#{purchase_att}_items_conditioning_unit > .controls > .selector > .selector-search")
          selector_value = $(that.closest('tr')).find(".#{purchase_att}_items_conditioning_unit > .controls > .selector > .selector-value")
          len = 4 * Math.round(Math.round(1.11 * data.unit_name.length) / 4)
          element.attr 'size', if len < 20 then 20 else if len > 80 then 80 else len
          element.val data.unit_name
          selector_value.prop 'itemLabel', data.unit_name
          selector_value.val data.unit_id
          selector_value.trigger 'selector:change'

    $(document).on 'selector:change', ".#{purchase_att}_items_conditioning_unit > .controls > .selector > .selector-value", ->
      that = this;
      $.ajax '/backend/conditioning_ratio',
        type: 'get'
        dataType: 'json'
        data: 'id': @value
        success: (data) ->
          table = $(that).closest('tr')
          coeff = 1
          if data.coeff and data.coeff != 1
            coeff = data.coeff
            $(table).find('.unitary-quantity').show()
          $(table).find(".#{purchase_att}_items_unit_pretax_amount > .controls > .input-append > input").data 'coeff', coeff
          amount_input = $(table).find(".#{purchase_att}_items_unit_pretax_amount > .controls > .input-append > input")
          unit_amount = (amount_input.val() / amount_input.data().coeff).toFixed(1)
          $(table).find(".#{purchase_att}_items_base_unit_amount > .controls > .input-append > input").val unit_amount

  E.Purchases =
    compute_amount: ->
      $pretaxAmounts = $('.nested-fields .pre-tax-invoice-total-controls input')
      pretaxAmount = $pretaxAmounts.toArray().reduce(((acc, e) => acc + parseFloat(e.value)), 0).toFixed(2)
      $preTaxTotal = $('.total-except-tax .total-value')
      $preTaxTotal.text(pretaxAmount)

      $taxAmounts = $('.nested-fields .invoice-total-controls input')
      taxAmount = $taxAmounts.toArray().reduce(((acc, e) => acc + parseFloat(e.value)), 0).toFixed(2)
      $taxTotal = $('.purchase-total .total-value')
      $taxTotal.text(taxAmount)

      $vatTotal = $('.vat-total .total-value')
      $vatTotal.text((taxAmount - pretaxAmount).toFixed(2))

) ekylibre, jQuery
