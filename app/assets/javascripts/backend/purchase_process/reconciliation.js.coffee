((E, $) ->
  'use strict'

  $(document).on 'change', '#purchase_invoice_accepted_state', (event) ->
    checked = $(event.target).is(':checked')

    if checked
      E.reconciliation.displayAcceptedState(event)
    else
      isReconciliate = false
      $('.purchase-item-attribute').each (index, purchaseItemAttribute) ->
        if $(purchaseItemAttribute).val() != undefined && $(purchaseItemAttribute).val() != ""
          isReconciliate = true

      if isReconciliate
        E.reconciliation.displayReconciliateState(event)
      else
        E.reconciliation.displayNoReconciliateState(event)

  $(document).on 'click', '#showReconciliationModal', (event) ->
    event.stopPropagation()
    E.reconciliation.displayReconciliationModal(event, {})


  $(document).on 'click', '#showItemReconciliationModal', (event) ->
    event.stopPropagation()
    itemFieldId = $(event.target).closest('.form-field').find('.purchase-item-attribute').attr('id')
    E.reconciliation.displayReconciliationModal(event, { reconciliate_item: true, item_field_id: itemFieldId })


  $(document).ready ->
    if $('#purchase_process_reconciliation').length > 0
      $('#main .heading-toolbar').addClass('purchase-process-reconciliation')
    if $('#purchase_invoice_accepted_state').is(':checked')
      E.reconciliation.displayAcceptedState()

  $(document).on 'change', '#purchase_process_reconciliation .model-checkbox', (event) ->
    checked = $(event.target).is(':checked')
    $(event.target).closest('.model').find('.item-checkbox').prop('checked', checked)


  $(document).on 'click', '#purchase_process_reconciliation .valid-modal', (event) ->
    validButton = $(event.target)
    modal = $(event.target).closest('#purchase_process_reconciliation')

    if validButton.attr('data-item-reconciliation') != undefined
      E.reconciliation.reconciliateItems(modal)
    else
      E.reconciliation.createLinesWithSelectedItems(modal, event)

    E.reconciliation.displayReconciliateState(event)

    @reconciliationModal= new E.modal('#purchase_process_reconciliation')
    @reconciliationModal.getModal().modal 'hide'


  E.reconciliation =
    displayReconciliateState: (event) ->
      $('#purchase_invoice_accepted_state').val('reconcile')
      $('#purchase_invoice_reconciliate_state').val('reconcile')
      $('#reception_reconciliation_state').val('reconcile')

      # Change the state title
      if $('.accepted-title').length > 0 && $('.accepted-title').hasClass('hidden')
        $('.no-reconciliate-title').addClass('hidden')
      else if $('.reconcile-title').length > 0 && $('.reconcile-title').hasClass('hidden')
        $('.no-reconciliate-title').addClass('hidden')
      else
        $('.accepted-title').addClass('hidden')

      $('.reconcile-title').removeClass('hidden')

      # Change the state main field
      if $('.accepted-state').length > 0 && $('.accepted-state').hasClass('hidden')
        $('.no-reconciliate-state').addClass('hidden')
      else if $('.reconcile-state').length > 0 && $('.reconcile-state').hasClass('hidden')
        $('.no-reconciliate-state').addClass('hidden')
      else
        $('.accepted-state').addClass('hidden')

      $('.reconcile-state').removeClass('hidden')


    displayAcceptedState: (event) ->
      $('#purchase_invoice_accepted_state').val('accepted')
      $('#purchase_invoice_reconciliate_state').val('to_reconcile')

      # Change the state title
      if $('.reconcile-title').hasClass('hidden')
        $('.no-reconciliate-title').addClass('hidden')
      else
        $('.reconcile-title').addClass('hidden')

      $('.accepted-title').removeClass('hidden')

      # Change the state main field
      if $('.reconcile-state').hasClass('hidden')
        $('.no-reconciliate-state').addClass('hidden')
      else
        $('.reconcile-state').addClass('hidden')

      $('.accepted-state').removeClass('hidden')


    displayNoReconciliateState: (event) ->
      $('#purchase_invoice_accepted_state').val('accepted')
      $('#purchase_invoice_reconciliate_state').val('to_reconcile')
      $('#reception_reconciliation_state').val('to_reconcile')

      # Change the state title
      if $('.accepted-title').length > 0 && $('.accepted-title').hasClass('hidden')
        $('.reconcile-title').addClass('hidden')
      else
        $('.accepted-title').addClass('hidden')

      $('.no-reconciliate-title').removeClass('hidden')

      # Change the state main field
      if $('.accepted-state').length > 0 && $('.accepted-state').hasClass('hidden')
        $('.reconcile-state').addClass('hidden')
      else
        $('.accepted-state').addClass('hidden')

      $('.no-reconciliate-state').removeClass('hidden')

    displayReconciliationModal: (event, datas) ->
      isPurchaseInvoiceForm = $(event.target).closest('.simple_form').hasClass('new_purchase_invoice')
      isNewReception = $(event.target).closest('.simple_form').hasClass('new_reception')

      url = "/backend/purchase_process/reconciliation/purchase_orders_to_reconciliate"
      if isPurchaseInvoiceForm
        url = "/backend/purchase_process/reconciliation/receptions_to_reconciliate"
        datas['supplier'] = $('input[name="purchase_invoice[supplier_id]').val()
      else if isNewReception
        datas['supplier'] = $('input[name="reception[sender_id]').val()

      $.ajax
        url: url
        data: datas
        success: (data, status, request) ->

          @reconciliationModal= new E.modal('#purchase_process_reconciliation')
          @reconciliationModal.removeModalContent()
          @reconciliationModal.getModalContent().append(data)
          @reconciliationModal.getModal().modal 'show'


    reconciliateItems: (modal) ->
      checkedItemId = $(modal).find('.item-checkbox:checked').attr('data-id')
      itemFieldId = $('.item-checkbox:checked').attr('data-item-field-id')

      if $('#purchase-orders').val() == "false"
        $("##{itemFieldId}").val(JSON.stringify([checkedItemId]))
      else
        $("##{itemFieldId}").val(checkedItemId)


    createLinesWithSelectedItems: (modal, event) ->
      itemsCheckboxes = $(modal).find('.item-checkbox:checked')

      itemsCheckboxes.each (index, itemCheckbox) ->
        isPurchaseOrderModal = $(itemCheckbox).closest('.modal-content').find('#purchase-orders').val()

        if isPurchaseOrderModal == "true"
          E.reconciliation._createNewReceptionItemLine(itemCheckbox)
        else
          E.reconciliation._createNewPurchaseInvoiceItemLine(itemCheckbox)

        E.reconciliation._fillNewLineForm(itemCheckbox, isPurchaseOrderModal)


    _createNewReceptionItemLine: (itemCheckbox) ->
      variantType = $(itemCheckbox).closest('.item').attr('data-variant-type')
      buttonToClickSelector = $('table.list #items-footer .add-merchandise')

      if variantType == "service"
        buttonToClickSelector = $('table.list #items-footer .add-service')
      else if variantType == "cost"
        buttonToClickSelector = $('table.list #items-footer .add-cost')

      $(buttonToClickSelector).find('.add_fields').trigger('click')


    _createNewPurchaseInvoiceItemLine: (itemCheckbox) ->
      $('table.list #items-footer .links .add_fields').trigger('click')


    _fillNewLineForm:  (itemCheckbox, isPurchaseOrderModal) ->
      lastLineForm = $('table.list .nested-fields .nested-item-form:last:visible')

      checkboxLine = $(itemCheckbox).closest('.item')
      itemId = $(itemCheckbox).attr('data-id')
      itemQuantity = $(checkboxLine).find('.item-value.quantity').text()
      equipmentId = $(checkboxLine).attr('data-equipment-id')

      if isPurchaseOrderModal == "true"
        E.reconciliation._fillPurchaseOrderItem(lastLineForm, checkboxLine, itemId, itemQuantity)
      else
        E.reconciliation._fillReceptionItem(lastLineForm, checkboxLine, itemId, itemQuantity)

      $(lastLineForm).find('input[data-remember="equipment"]').first().selector('value', equipmentId)
      $(lastLineForm).find('.no-reconciliate-item-state').addClass('hidden')
      $(lastLineForm).find('.reconciliate-item-state').removeClass('hidden')


    _fillReceptionItem: (lastLineForm, checkboxLine, itemId, itemQuantity) ->
      variantId = $(checkboxLine).find('.variant').attr('data-id')
      teamId = $(checkboxLine).attr('data-team-id')
      activityBudgetId = $(checkboxLine).attr('data-activity-budget-id')

      itemUnitCost = $(checkboxLine).find('.item-value.unit-cost').text()
      itemTotalAmount = $(checkboxLine).find('.item-value.total-except-taxes').text()
      itemReductionPercentage = $(checkboxLine).attr('data-reduction-percentage')

      if itemReductionPercentage == "" || itemReductionPercentage == undefined
        itemReductionPercentage = 0

      $(lastLineForm).find('.purchase-item-attribute').val(JSON.stringify([itemId]))

      $(lastLineForm).find('.form-field .invoice-quantity').val(itemQuantity)
      $(lastLineForm).find('.form-field .invoice-unit-amount').val(itemUnitCost)
      $(lastLineForm).find('.form-field .invoice-discount-percentage').val(itemReductionPercentage)
      $(lastLineForm).find('.form-field .invoice-total').val(itemTotalAmount)
      $(lastLineForm).find('.form-field.merchandise .selector-search').first().selector('value', variantId)
      $(lastLineForm).find('.form-field .purchase_invoice_items_activity_budget .selector-search').first().selector('value', activityBudgetId)
      $(lastLineForm).find('.form-field .purchase_invoice_items_team .selector-search').first().selector('value', teamId)


    _fillPurchaseOrderItem: (lastLineForm, checkboxLine, itemId, itemQuantity) ->
      variantId = $(checkboxLine).find('.variant').attr('data-id')

      $(lastLineForm).find('.purchase-item-attribute').val(itemId)

      $(lastLineForm).find('.item-block.merchandise .parcel-item-variant').first().selector('value', variantId)
      $(lastLineForm).find('.hidden.purchase-item-attribute').val(itemId)
      $(lastLineForm).find('.nested-fields.storing-fields:first .storing-quantifier .storing-quantity').val(itemQuantity)

) ekylibre, jQuery
