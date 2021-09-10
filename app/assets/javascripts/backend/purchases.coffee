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
