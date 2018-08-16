((E, $) ->
  'use strict'

  $(document).ready ->
    if $('.change-reconcilation-state-block').length > 0
      E.PurchaseInvoicesShow.addStyleToReconcilationStateBlock()

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

        if amountExcludingTaxes == "??????" || amountIncludingTaxes == "??????" || vatRate == "??????"
          return

        totalAmountExcludingTaxes += parseFloat(amountExcludingTaxes)
        totalAmountIncludingTaxes += parseFloat(amountIncludingTaxes)

        calculVatRate = parseFloat(amountExcludingTaxes) * parseFloat(vatRate) / 100
        totalVatRate += calculVatRate

        selectedVatValue = $(item).parent().find('.nested-item-form select.invoice-vat-total option:selected').val()
        $(item).find('.vat-rate').attr('data-selected-value', selectedVatValue)

      $('.invoice-totals .total-except-tax .total-value').text(parseFloat(totalAmountExcludingTaxes).toFixed(2))
      $('.invoice-totals .vat-total .total-value').text(parseFloat(totalVatRate).toFixed(2))
      $('.invoice-totals .invoice-total .total-value').text(parseFloat(totalAmountIncludingTaxes).toFixed(2))


    $(document).on 'selector:change', '.invoice-variant.selector-search', (event) ->
      E.PurchaseInvoices.fillStocksCounters(event)

      targettedElement = $(event.target)
      fieldAssetFields = targettedElement.closest('.merchandise').find('.fixed-asset-fields')

      fixedAssetCheckbox = fieldAssetFields.find('.purchase_invoice_items_fixed input[type="checkbox"]')
      preexistingCheckbox = fieldAssetFields.find('.purchase_invoice_items_preexisting_asset input[type="checkbox"]')
      depreciableProductField = fieldAssetFields.find('.purchase_invoice_items_depreciable_product .selector-value')
      fixedAssetField = fieldAssetFields.find('.purchase_invoice_items_fixed_asset .selector-value')
      stoppedOnField = fieldAssetFields.find('.purchase_invoice_items_fixed_asset_stopped_on input')

      fixedAssetCheckbox.prop('checked', false)
      fixedAssetCheckbox.trigger('change')

      preexistingCheckbox.prop('checked', false)
      preexistingCheckbox.trigger('change')

      depreciableProductField.val('')
      fixedAssetField.val('')
      stoppedOnField.val('')


    $(document).on 'change', '.nested-fields .form-field .purchase_invoice_items_quantity .invoice-quantity', (event) ->
      E.PurchaseInvoices.fillStocksCounters(event)

    $(document).on 'keyup', '.nested-fields .form-field .purchase_invoice_items_quantity .invoice-quantity', (event) ->
      E.PurchaseInvoices.fillStocksCounters(event)

    $(document).on 'click', '.nested-fields .edit-item[data-edit="item-form"]', (event) ->
      vatSelectedValue = $(event.target).closest('.nested-fields').find('.item-display .vat-rate').attr('data-selected-value')
      $(event.target).closest('.nested-fields').find('.nested-item-form:visible .invoice-vat-total').val(vatSelectedValue)

    $('#new_purchase_invoice table.list').bind 'cocoon:after-insert', (event, insertedItem) ->
      return if !insertedItem?
      new_id = new Date().getTime()

      insertedItem.attr('id', "new_reception_#{new_id}")

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


    $(document).on 'change', '.nested-item-form .fixed-asset-fields .purchase_invoice_items_fixed input[type="checkbox"]', (event) ->
      targettedElement = $(event.target)
      E.PurchaseInvoices.displayAssetsBlock(targettedElement)

      if targettedElement.is(':checked')
        E.PurchaseInvoices.manageStoppedOnFieldDisplay(targettedElement)


    $(document).on 'change', '.nested-item-form .fixed-asset-fields .purchase_invoice_items_preexisting_asset input[type="checkbox"]', (event) ->
      targettedElement = $(event.target)
      E.PurchaseInvoices.manageExistingAssetDisplay(targettedElement)

      unless targettedElement.is(':checked')
        E.PurchaseInvoices.manageStoppedOnFieldDisplay(targettedElement)


    $(document).on 'click', '.change-reconcilation-state-block input[type="checkbox"]', (event) ->
      checkbox = $(event.target)
      E.PurchaseInvoicesShow.changeEventReconcilationStateBlock(checkbox)


  E.PurchaseInvoices =
    displayAssetsBlock: (fixedCheckbox) ->
      fixedAssetFields = fixedCheckbox.closest('.fixed-asset-fields')
      assetBlock = $(fixedAssetFields).find('.assets')

      if fixedCheckbox.is(':checked')
        assetBlock.css('display', 'block')
      else
        assetBlock.css('display', 'none')


    manageExistingAssetDisplay: (preexistingCheckbox) ->
      assetsFields = preexistingCheckbox.closest('.assets')
      existingAssetBlock = $(assetsFields).find('.existing_asset')
      newAssetBlock = $(assetsFields).find('.new_asset')

      if preexistingCheckbox.is(':checked')
        existingAssetBlock.css('display', 'block')
        newAssetBlock.css('display', 'none')
      else
        existingAssetBlock.css('display', 'none')
        newAssetBlock.css('display', 'block')


    manageStoppedOnFieldDisplay: (checkbox) ->
      assetsFields = checkbox.closest('.assets')
      assetsFields = checkbox.closest('.fixed-asset-fields').find('.assets') if assetsFields.length == 0

      stoppedOnFieldBlock = assetsFields.find('.fixed-asset-stopped-on')

      merchandise = checkbox.closest('.merchandise')
      variantId = merchandise.find('.purchase_invoice_items_variant .selector-value').val()

      $.ajax
        url: "/backend/variants/fixed_assets/#{variantId}/fixed_assets_datas",
        success: (data, status, request) ->
          if data.depreciation_method == "simplified_linear" || data.depreciation_method == ""
            stoppedOnFieldBlock.css('display', 'none')
          else
            stoppedOnFieldBlock.css('display', 'block')


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


  E.PurchaseInvoicesShow =
    addStyleToReconcilationStateBlock: ->
      reconcilationStateBlock = $('.change-reconcilation-state-block')
      mainToolbar = reconcilationStateBlock.closest('.main-toolbar')

      reconcilationStateBlock.css('float', 'right')
      reconcilationStateBlock.css('margin-right', '2em')
      mainToolbar.css('width', '100%')


    changeEventReconcilationStateBlock: (checkbox) ->
      reconciliationTitle = $('.reconciliation-title')
      purchase_invoice_id = window.location.pathname.split('/').pop()
      isReconcile = $(reconciliationTitle).attr('data-reconcile') == 'true'
      url = "/backend/purchases/reconcilation_states/#{ purchase_invoice_id }"

      if checkbox.is(':checked')
        url += '/put_accepted_state'
      else
        url += '/put_reconcile_state' if isReconcile
        url += '/put_to_reconcile_state' unless isReconcile

      $.ajax
        url: url,
        success: (data, status, request) ->
          if checkbox.is(':checked')
            reconciliationTitle.addClass('accepted-title')
            reconciliationTitle.text(reconciliationTitle.attr('data-accepted-text'))

            reconciliationTitle.removeClass('no-reconciliate-title') if isReconcile
            reconciliationTitle.removeClass('reconciliate-title') unless isReconcile
          else
            reconciliationTitle.removeClass('accepted-title')

            if $(reconciliationTitle).attr('data-reconcile') == 'true'
              reconciliationTitle.addClass('reconcile-title')
              reconciliationTitle.text(reconciliationTitle.attr('data-reconcile-text'))
            else
              reconciliationTitle.addClass('no-reconciliate-title')
              reconciliationTitle.text(reconciliationTitle.attr('data-no-reconciliate-text'))


) ekylibre, jQuery
