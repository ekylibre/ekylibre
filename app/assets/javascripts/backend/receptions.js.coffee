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

  updateTotalStockAfterReception = ($form, newStock, currentStock) =>
    $totalQuantityAfterReception = $form.find(".merchandise-total-stock-after-reception .stock-value")
    stockReceived = (newStock - currentStock).toFixed(2)
    $totalQuantityAfterReception.data('interpolate-data-attribute', stockReceived)
    $totalQuantityAfterReception.attr('data-interpolate-data-attribute', stockReceived)
    $totalQuantityAfterReception.text(newStock.toFixed(2))

  computeTotalQuantity = ($form) =>
    reducer = (acc, val) ->
      acc + parseFloat(val)

    $form.find('.storing-fields')
      .map(-> ($(this).find('.storing-quantity').val() || 0) * ($(this).find('[data-coefficient]').data('coefficient') || 0))
      .toArray()
      .reduce(reducer, .0)

  onQuantityChanged = ($input) =>
    $form = $input.closest('.nested-item-form')
    $storageForm = $input.closest('.nested-fields')
    $storage = $($storageForm.find(".parcel-item-storage.selector-search").get(0))
    coefficient = $form.find('[data-coefficient]').data('coefficient')
    if coefficient && $storage.selector('value')
      updateAfterReceptionQuantity($storage.closest('.nested-fields'))
      recomputeTotalQuantity($form)

  recomputeTotalQuantity = ($form) =>
    totalQuantity = computeTotalQuantity($form)
    onTotalQuantityChanged $form, totalQuantity

  onTotalQuantityChanged = ($form, totalQuantity) =>
    currentStock = getCurrentStock($form)
    if totalQuantity.length == 0
      newStock = currentStock
    else
      newStock = currentStock + parseFloat(totalQuantity)
    updateTotalStockAfterReception($form, newStock, currentStock)

  getCurrentStock = ($form) =>
    parseFloat($form.find('.merchandise-total-current-stock .stock-value').text())

  getVariantStock = (variantId) =>
    $.getJSON("/backend/product_nature_variants/#{variantId}/detail")
      .then (data) =>
        {
          stock: data.default_unit_stock,
          unit: data.default_unit_name,
          unitId: data.default_unit_id,
          isEquipment: data.is_equipment
        }

  getStorageStock = (variantId, storageId) =>
    $.getJSON("/backend/product_nature_variants/#{variantId}/storage_detail", storage_id: storageId)
      .then (data) =>
        {
          stock: data.quantity,
          unit: data.unit,
          name: data.name
        }

  updateAfterReceptionQuantity = ($storage) =>
    storingQuantity = $storage.find('.storing-quantity').val() || 0
    currentStock = $storage.find('.merchandise-current-stock .stock-value').text()
    coefficient = $storage.find('[data-coefficient]').data('coefficient')
    stockAfterReception = parseFloat(storingQuantity * coefficient) + parseFloat(currentStock)
    $storage.find('.merchandise-stock-after-reception .stock-value').text(stockAfterReception.toFixed(2))

  onStorageChanged = ($storageSelector) =>
    $form = $storageSelector.closest('.nested-item-form')
    $storage = $storageSelector.closest('.nested-fields')

    storageId = $storageSelector.selector('value')
    variantId = $($form.find(".parcel-item-variant.selector-search").get(0)).selector('value')

    if variantId && storageId
      getStorageStock(variantId, storageId).then (data) =>
        $storage.find(".merchandise-current-stock .stock-value").text(parseFloat(data.stock).toFixed(2))
        $storage.find(".stock-unit").text(data.unit)
        $storageSelector.data('storage-name', data.name)
        $storageSelector.attr('data-storage-name', data.name)
        updateAfterReceptionQuantity $storage
        recomputeTotalQuantity $form

  onvariantChanged = ($variantSelector) =>
    $form = $variantSelector.closest('.nested-item-form')
    $conditioningSelector = $form.find('.reception-conditionning').first()
    variantId = $variantSelector.selector('value')
    getVariantStock(variantId).then (data) =>
      if data.isEquipment
        $conditioningSelector.selector('value', data.unitId, (-> E.reconciliation.disableSelectorInput($conditioningSelector);$conditioningSelector.trigger('selector:change')))
      updateQuantities($form)
      $form.find(".stock-unit").text(data.unit)
      $form.find(".merchandise-total-current-stock .stock-value").text(parseFloat(data.stock).toFixed(2))
      $form.find('.storing-quantity').trigger('change')
      $form.find('input.parcel-item-storage').trigger('selector:change')

  onStorageAdded = ($storageLine) =>
    $storageLine.closest('.nested-item-form').find('[data-filter-unroll]').trigger('selector:change')
    $input = $storageLine.find('.storing-quantity')
    updateQuantity $input

  updateQuantity = ($input) =>
    if $input.val() == "0" || $input.val() == ""
      $input.val(1)
    $input.trigger('change')

  updateQuantities = ($form) =>
    $form.find('.storing-quantity').each -> updateQuantity $(this)

  $(document).on 'selector:change', '.reception_sender .controls .selector, .purchase_invoice_supplier .controls .selector', (event) ->
    $('#showReconciliationModal').removeClass('disabled')

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
