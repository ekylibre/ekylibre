((E, $) ->
  'use strict'

  $(document).ready ->
    $('table.list').on 'cocoon:after-insert', (event, $insertedItem) ->
      $('*[data-iceberg]').on "iceberg:inserted", ->
        that = $(this)
        $(this).find('*[data-association]').each (i, cocoonBtn) ->
          node = $(cocoonBtn).data('association-insertion-node')
          storageContainer = $(node).parent()
          storageContainer.on 'cocoon:after-insert cocoon:after-remove', ->
            E.toggleValidateButton(that)
            E.setStorageUnitName(that)

      if $insertedItem && $insertedItem.hasClass('storing-fields')
        unitName = $insertedItem.closest('.item-block__storing').find('.storage-unit-name').first().text()
        $insertedItem.find('.storage-unit-name').text(unitName)

    $('.new_reception, .edit_reception').on 'change', '#reception_reconciliation_state', (event) ->
      checked = $(event.target).is(':checked')

      if checked
        $(event.target).val('accepted')
      else
        $(event.target).val('to_reconciliate')

  updateTotalStockAfterReception = ($form, newstock) =>
    $form.find(".merchandise-total-stock-after-reception .stock-value").text(newstock.toFixed(2))

  computeTotalQuantity = ($form) =>
    reducer = (acc, val) ->
      acc + parseFloat(val)

    $form.find('.storing-quantity')
      .map(-> $(this).val() || 0)
      .toArray()
      .reduce(reducer, .0)

  onQuantityChanged = ($input) =>
    $form = $input.closest('.nested-item-form')
    $storageForm = $input.closest('.nested-fields')
    $storage = $($storageForm.find(".parcel-item-storage.selector-search").get(0))
    recomputeTotalQuantity($form)
    updateAfterReceptionQuantity($storage.closest('.nested-fields'))

  recomputeTotalQuantity = ($form) =>
    totalQuantity = computeTotalQuantity($form)
    onTotalQuantityChanged $form, totalQuantity

  onTotalQuantityChanged = ($form, totalQuantity) =>
    newQuantity = totalQuantity
    currentstock = getCurrentStock($form)
    if newQuantity.length == 0
      newStock = currentstock
    else
      newStock = currentstock + parseFloat(newQuantity)
    updateTotalStockAfterReception($form, newStock)

  getCurrentStock = ($form) =>
    parseFloat($form.find('.merchandise-total-current-stock .stock-value').text())

  getVariantStock = (variantId) =>
    $.getJSON("/backend/product_nature_variants/#{variantId}/detail")
      .then (data) =>
        {
          stock: data.stock,
          unit: data.unit.name
        }

  getStorageStock = (variantId, storageId) =>
    $.getJSON("/backend/product_nature_variants/#{variantId}/storage_detail", storage_id: storageId)
      .then (data) =>
        {
          stock: data.quantity,
          unit: data.unit
        }

  updateAfterReceptionQuantity = ($storage) =>
    storingQuantity = $storage.find('.storing-quantity').val() || 0
    currentStock = $storage.find('.merchandise-current-stock .stock-value').text()
    stockAfterReception = parseFloat(storingQuantity) + parseFloat(currentStock)
    $storage.find('.merchandise-stock-after-reception .stock-value').text(stockAfterReception)

  onStorageChanged = ($storageSelector) =>
    $form = $storageSelector.closest('.nested-item-form')
    $storage = $storageSelector.closest('.nested-fields')

    storageId = $storageSelector.selector('value')
    variantId = $($form.find(".parcel-item-variant.selector-search").get(0)).selector('value')

    getStorageStock(variantId, storageId).then (data) =>
      $storage.find(".merchandise-current-stock .stock-value").text(data.stock)
      $storage.find(".stock-unit").text(data.unit)
      updateAfterReceptionQuantity $storage

  onvariantChanged = ($variantSelector) =>
    $form = $variantSelector.closest('.nested-item-form')

    variantId = $variantSelector.selector('value')
    getVariantStock(variantId).then (data) =>
      $form.find(".merchandise-total-current-stock .stock-value").text(data.stock)
      $form.find(".stock-unit").text(data.unit)
      updateQuantities($form)

  onStorageAdded = ($storageLine) =>
    $input = $storageLine.find('.storing-quantity')
    updateQuantity $input

  updateQuantity = ($input) =>
    if $input.val() == "0" || $input.val() == ""
      $input.val(1)
    $input.trigger('change')

  updateQuantities = ($form) =>
    $form.find('.storing-quantity').each -> updateQuantity $(this)

  $(document).on 'keyup change', '.nested-fields .item-form__role .storing-quantifier .storing-quantity', (event) ->
    onQuantityChanged $(this)

  $(document).on 'selector:change', '.parcel-item-variant.selector-search', (event) ->
    onvariantChanged $(this)

  $(document).on 'selector:change', '.parcel-item-storage.selector-search', (event) ->
    onStorageChanged $(this)

  $(document).on 'cocoon:after-insert', '.storing-row', (event, $insertedRow) ->
    onStorageAdded $insertedRow

  $(document).on 'cocoon:after-remove', '.storing-row', (event) ->
    recomputeTotalQuantity $(this).closest('.nested-item-form')

) ekylibre, jQuery
