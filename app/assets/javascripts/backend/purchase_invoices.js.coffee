((E, $) ->
  'use strict'

  $(document).ready ->
    reconciliation_badges = new StateBadgeSet('#reconciliation-badges')

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

        selectedVatValue = $(item).parent().find('.nested-item-form select.vat-total option:selected').val()
        $(item).find('.vat-rate').attr('data-selected-value', selectedVatValue)

      $('.invoice-totals .total-except-tax .total-value').text(parseFloat(totalAmountExcludingTaxes).toFixed(2))
      $('.invoice-totals .vat-total .total-value').text(parseFloat(totalVatRate).toFixed(2))
      $('.invoice-totals .invoice-total .total-value').text(parseFloat(totalAmountIncludingTaxes).toFixed(2))

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

    $('#new_purchase_invoice').on 'iceberg:validated', E.Purchases.compute_amount
    $('.edit_purchase_invoice').on 'iceberg:validated', E.Purchases.compute_amount
    $('#new_purchase_invoice').on 'cocoon:after-remove', E.Purchases.compute_amount
    $('.edit_purchase_invoice').on 'cocoon:after-remove', E.Purchases.compute_amount

    $('#new_purchase_invoice table.list, .edit_purchase_invoice table.list').on 'cocoon:after-insert', (event, insertedItem) ->
          if typeof insertedItem != 'undefined'
            new_id = insertedItem.html().match(new RegExp('\\[(\\d+)\\]'))[1] #HACK: Get id from inputs
            new_id = new_id || new Date().getTime()

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

    $(document).on 'change', '.nested-item-form .fixed-asset-fields .purchase_invoice_items_preexisting_asset input[type="checkbox"]', (event) ->
      targettedElement = $(event.target)
      E.PurchaseInvoices.manageExistingAssetDisplay(targettedElement)

    $(document).on 'click', '.change-reconciliation-state-block input[type="checkbox"]', (event) ->
      checkbox = $(event.target)
      E.PurchaseInvoicesShow.changeEventReconciliationStateBlock(checkbox)

    E.PurchaseInvoicesShow =
      changeEventReconciliationStateBlock: (checkbox) ->
        reconciliationTitle = $('.reconciliation-title')
        purchase_invoice_id = window.location.pathname.split('/').pop()
        isReconcile = $(reconciliationTitle).attr('data-reconcile') == 'true'
        url = "/backend/purchases/reconciliation_states/#{ purchase_invoice_id }"

        if checkbox.is(':checked')
          url += '/put_accepted_state'
        else
          url += '/put_reconcile_state' if isReconcile
          url += '/put_to_reconcile_state' unless isReconcile

        $.get(url).then =>
          if checkbox.is(':checked')
            reconciliation_badges.setState 'accepted'
          else
            reconciliation_badges.setState 'to-reconcile'

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
  
  urlParams = ->
    queryString = window.location.search
    new URLSearchParams(queryString)

  undisabledInputOnNewPurchaseInvoiceItem = ->
    if urlParams().get('mode') == 'prefilled'
      document.querySelectorAll('input[data-selector-id=\'purchase_item_variant_id\']').forEach (currentValue) ->
        if currentValue['value'] == ''
          currentValue.disabled = false
        return
    return

  $(document).on 'cocoon:after-insert', '#new_purchase_invoice', (e) ->
    undisabledInputOnNewPurchaseInvoiceItem()
    return

) ekylibre, jQuery
