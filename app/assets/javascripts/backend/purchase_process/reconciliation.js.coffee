((E, $) ->
  'use strict'

  set_reconciliation_state = (reconciliation_state) =>
    if reconciliation_state
      $('.no-reconciliate-title').addClass('hidden')
      $('.no-reconciliate-state').addClass('hidden')
      $('.reconcile-title').removeClass('hidden')
      $('.reconcile-state').removeClass('hidden')
    else
      $('.no-reconciliate-title').removeClass('hidden')
      $('.no-reconciliate-state').removeClass('hidden')
      $('.reconcile-title').addClass('hidden')
      $('.reconcile-state').addClass('hidden')


  refresh_state = ->
    $displayComplianceStates = $(".nested-fields .nested-item-form[data-non-compliant='true']")

    set_reconciliation_state !!$('.nested-fields .nested-item-form[data-item-id]').length

    if !$displayComplianceStates.length
      $('.compliance-title').addClass('hidden')
    else
      $('.compliance-title').removeClass('hidden')

  disable_selector_input = ($selector_input) =>
    $selector_input.prop('disabled', true)
    $selector_input.siblings(':last').addClass('disabled')

  prevent_unroll_edition_for_reconciliated_items = (e, data) ->
    target = data if data
    target ||= e.target
    target = $(target).closest('tbody') unless $(target).is('tbody')

    if $(target).find('.nested-item-form[data-item-id]').length
      disable_selector_input $(target).find('input[id*="variant"]')


  $(document).on 'cocoon:after-insert', '#new_reception, #new_purchase_invoice, .edit_reception, .edit_purchase_invoice', prevent_unroll_edition_for_reconciliated_items
  $(document).on 'cocoon:after-remove', '#new_reception, #new_purchase_invoice, .edit_reception, .edit_purchase_invoice', refresh_state

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


  $(document).ready ->
    if $('#purchase_process_reconciliation').length > 0
      $('#main .heading-toolbar').addClass('purchase-process-reconciliation')
    # Display the correct value for reconciliation_state in edit view
    if $('#purchase_invoice_accepted_state').is(':checked')
      E.reconciliation.displayAcceptedState()
    else if $('.simple_form').is('.edit_purchase_invoice, .edit_reception')
      url = $('.simple_form').attr('action') + ".json"
      $.get
        url : url
        success: (data, status, request) ->
          if data.reconciliation_state == "reconcile"
            E.reconciliation.displayReconciliateState()

  $(document).on 'change', '#purchase_process_reconciliation .model-checkbox', (event) ->
    checked = $(event.target).is(':checked')
    $(event.target).closest('.model').find('.item-checkbox').prop('checked', checked)

    E.reconciliation.displayClosePurchaseOrderBlock(event)

  $(document).on 'change', '#purchase_process_reconciliation .item-checkbox', (event) ->
    E.reconciliation.displayClosePurchaseOrderBlock(event)

  $(document).on 'click', '#purchase_process_reconciliation .valid-modal', (event) ->
    modal = $(event.target).closest('#purchase_process_reconciliation')

    displayedItemIds = $('.nested-fields .nested-item-form[data-item-id]').map(-> $(this).attr('data-item-id')).toArray()

    if $(this).attr('data-item-reconciliation') != undefined
      # Reconciliation on line
      E.reconciliation.reconciliateItems(modal)
      itemCheckbox = $(modal).find('.item-checkbox:checked')
      isPurchaseOrderModal = $('#purchase-orders').val()
      E.reconciliation._fillNewLineForm(itemCheckbox, isPurchaseOrderModal)
    else
      # Reconciliation on form
      E.reconciliation.createLinesWithSelectedItems(modal, displayedItemIds, event)
      E.reconciliation.removeLineWithUnselectedItems(modal, displayedItemIds, event)

    refresh_state()

    @reconciliationModal= new E.modal('#purchase_process_reconciliation')
    @reconciliationModal.getModal().modal 'hide'

  $(document).on 'click', '.item-form__btn .btn--cancel', refresh_state

  E.reconciliation =
    displayClosePurchaseOrderBlock: (event) ->
      targettedElement = $(event.target)
      modelBlock = $(targettedElement).closest('.model')
      closePurchaseOrderBlock = $(modelBlock).find('.close-purchase-order')
      #isCheckboxChecked = $(targettedElement).is(':checked')
      anyCheckboxChecked = $(modelBlock).find('input[type="checkbox"]').is(':checked')

      if anyCheckboxChecked && closePurchaseOrderBlock.is(':hidden')
        $(closePurchaseOrderBlock).removeClass('hidden')
      else if !anyCheckboxChecked && closePurchaseOrderBlock.is(':visible')
        $(closePurchaseOrderBlock).addClass('hidden')

    displayComplianceState: (event, modal) ->
      $nonCompliantItems = $(modal).find("li[data-non-compliant='true'] .item-checkbox:checked")

      if $nonCompliantItems.length
        $('.compliance-title').removeClass('hidden')

    displayReconciliateState: (event) ->
      $('#purchase_invoice_accepted_state').val('reconcile')
      $('#purchase_invoice_reconciliate_state').val('reconcile')
      $('#reception_reconciliation_state').val('reconcile')

      # Change the state title
      if $('.accepted-title').length > 0 && $('.accepted-title').hasClass('hidden')
        $('.no-reconciliate-title').addClass('hidden')
      else if $('.reconcile-title').length > 0 && $('.reconcile-title').hasClass('hidden')
        $('.no-reconciliate-title').addClass('hidden')
        $('.accepted-title').addClass('hidden')
      else
        $('.accepted-title').addClass('hidden')

      $('.reconcile-title').removeClass('hidden')

      # Change the state main field
      if $('.accepted-state').length > 0 && $('.accepted-state').hasClass('hidden')
        $('.no-reconciliate-state').addClass('hidden')
      else if $('.reconcile-state').length > 0 && $('.reconcile-state').hasClass('hidden')
        $('.no-reconciliate-state').addClass('hidden')
        $('.accepted-state').addClass('hidden')
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
      isPurchaseInvoiceForm = $(event.target).closest('.simple_form').is('.new_purchase_invoice, .edit_purchase_invoice')
      isReceptionForm = $(event.target).closest('.simple_form').is('.new_reception, .edit_reception')

      url = "/backend/purchase_process/reconciliation/purchase_orders_to_reconciliate"
      if isPurchaseInvoiceForm
        url = "/backend/purchase_process/reconciliation/receptions_to_reconciliate"
        datas['supplier'] = $('input[name="purchase_invoice[supplier_id]').val()
        $form = $('.edit_purchase_invoice')
        if $form.length
          action = $form.attr('action')
          datas['purchase_invoice'] = action.substr(action.lastIndexOf('/') + 1)
      else if isReceptionForm
        datas['supplier'] = $('input[name="reception[sender_id]').val()
        $form = $('.edit_reception')
        if $form.length
          action = $form.attr('action')
          datas['reception'] = action.substr(action.lastIndexOf('/') + 1)

      $.ajax
        url: url
        data: datas
        success: (data, status, request) ->
          @reconciliationModal= new E.modal('#purchase_process_reconciliation')
          @reconciliationModal.removeModalContent()
          @reconciliationModal.getModalContent().append(data)
          @reconciliationModal.getModal().modal 'show'
          E.reconciliation.editReconciliationModal(@reconciliationModal)

    editReconciliationModal: (modal) ->
      displayedItemIds = $('.nested-fields .nested-item-form[data-item-id]').map(-> $(this).attr('data-item-id')).toArray()

      for id in displayedItemIds
        $checkbox = modal.getModalContent().find("input[type='checkbox'][data-id=#{id}]")
        $checkbox.prop('checked', true) if $checkbox.length

    reconciliateItems: (modal) ->
      checkedItemId = $(modal).find('.item-checkbox:checked').attr('data-id')
      itemFieldId = $('.item-checkbox:checked').attr('data-item-field-id')

      if $('#purchase-orders').val() == "false"
        $("##{itemFieldId}").val(JSON.stringify([checkedItemId]))
      else
        $("##{itemFieldId}").val(checkedItemId)

    createLinesWithSelectedItems: (modal, displayedItemIds, event) ->
      itemsCheckboxes = $(modal).find('.item-checkbox:checked')

      itemsCheckboxes.each (index, itemCheckbox) ->
        return if displayedItemIds.includes $(itemCheckbox).attr('data-id')

        isPurchaseOrderModal = $(itemCheckbox).closest('.modal-content').find('#purchase-orders').val()
        E.reconciliation._createNewItemLine(itemCheckbox)

        if index == 0 && isPurchaseOrderModal == "false"

         responsibleId = $(itemCheckbox).closest('.item').attr('data-responsible-id')
         $('#purchase_invoice_responsible_id').first().selector('value', responsibleId)

        E.reconciliation._fillNewLineForm(itemCheckbox, isPurchaseOrderModal)

    removeLineWithUnselectedItems: (modal, displayedItemIds, event) ->
      for id in displayedItemIds
        $checkbox = $(modal).find("input[type='checkbox'][data-id=#{id}]")
        if $checkbox.length && !$checkbox.prop('checked')
          $container = $(".nested-fields .nested-item-form[data-item-id='#{id}'").closest('tbody')
          if $container.length
            $container.find('a.remove-item').click()
      return

    _createNewItemLine: (itemCheckbox) ->
      variantType = $(itemCheckbox).closest('.item').attr('data-variant-type')

      $buttonToClick = switch variantType
        when 'service' then $('.row-footer .add-service')
        when 'cost' then $('.row-footer .add-fees')
        else $('.row-footer .add-merchandise')

      $buttonToClick.find('.add_fields').trigger('click')

    _fillNewLineForm:  (itemCheckbox, isPurchaseOrderModal) ->
      lastLineForm = $('table.list .nested-fields .nested-item-form:last:visible')
      checkboxLine = $(itemCheckbox).closest('.item')
      itemId = $(itemCheckbox).attr('data-id')
      itemQuantity = $(checkboxLine).find('.item-value.quantity-to-fill').text()
      equipmentId = $(checkboxLine).attr('data-equipment-id')
      teamId = $(checkboxLine).attr('data-team-id')
      projectBudgetId = $(checkboxLine).attr('data-project-budget-id')
      activityBudgetId = $(checkboxLine).attr('data-activity-budget-id')
      itemConditionning = $(checkboxLine).attr('data-conditionning')
      itemConditionningQuantity = $(checkboxLine).attr('data-conditionning-quantity')
      itemCompliantState = $(checkboxLine).attr('data-non-compliant')

      $(lastLineForm).attr('data-item-id', itemId)
      $(lastLineForm).attr('data-non-compliant', itemCompliantState)

      if isPurchaseOrderModal == "true"
        E.reconciliation._fillPurchaseOrderItem(lastLineForm, checkboxLine, itemId, itemQuantity, itemConditionning, itemConditionningQuantity)
        fillStocks = =>
          E.Receptions.fillStocksCounters(lastLineForm)
      else
        E.reconciliation._fillReceptionItem(lastLineForm, checkboxLine, itemId, itemQuantity)
        fillStocks = =>
          E.Purchases.fillStocksCounters(lastLineForm)

      $(lastLineForm).find('input[data-remember="equipment"]').first().selector('value', equipmentId)
      $(lastLineForm).find('input[data-remember="team"]').first().selector('value', teamId)
      $(lastLineForm).find('input[data-remember="project_budget"]').first().selector('value', projectBudgetId)
      $(lastLineForm).find('input[data-remember="activity_budget"]').first().selector('value', activityBudgetId)
      $(lastLineForm).find('.no-reconciliate-item-state').addClass('hidden')
      $(lastLineForm).find('.reconciliate-item-state').removeClass('hidden')
      $line = $(lastLineForm).parent('.nested-fields')
      $line.data('_iceberg').bindSelectorsInitialization ->
        fillStocks()
        $line.data('_iceberg').setCocoonFormSubmitable()

    # Creates a line BASED on a ReceptionItem
    _fillReceptionItem: (lastLineForm, checkboxLine, itemId, itemQuantity) ->
      variantId = $(checkboxLine).find('.variant').attr('data-id')
      teamId = $(checkboxLine).attr('data-team-id')
      activityBudgetId = $(checkboxLine).attr('data-activity-budget-id')
      itemUnitCost = $(checkboxLine).find('.item-value.unit-cost').text()
      itemTotalAmount = $(checkboxLine).find('.item-value.total-except-taxes').text()
      itemReductionPercentage = $(checkboxLine).attr('data-reduction-percentage')
      itemTaxId = $(checkboxLine).attr('data-tax-id')
      itemConditionning = checkboxLine.attr('data-conditionning')
      itemConditionningQuantity = checkboxLine.attr('data-conditionning-quantity')
      itemSupplierReference = $(checkboxLine).attr('data-supplier-ref')

      if itemReductionPercentage == "" || itemReductionPercentage == undefined
        itemReductionPercentage = 0

      itemCompliantState = $(checkboxLine).attr('data-non-compliant')
      $(lastLineForm).attr('data-item-id', itemId)
      $(lastLineForm).attr('data-non-compliant', itemCompliantState)

      $(lastLineForm).find('.purchase-item-attribute').val(JSON.stringify([itemId]))
      $(lastLineForm).find('.form-field .invoice-quantity').val(itemQuantity)
      $(lastLineForm).find('.form-field .invoice-unit-amount').val(itemUnitCost)
      $(lastLineForm).find('.form-field .invoice-discount-percentage').val(itemReductionPercentage)
      $(lastLineForm).find('.form-field .pre-tax-invoice-total').val(itemTotalAmount)
      $selectorInput = $(lastLineForm).find('.form-field .invoice-variant').first()
      $selectorInput.selector('value', variantId, (-> disable_selector_input($selectorInput);$(lastLineForm).find('.form-field .invoice-quantity').trigger('change')))
      $(lastLineForm).find('.form-field .purchase_invoice_items_activity_budget .selector-search').first().selector('value', activityBudgetId)
      $(lastLineForm).find('.form-field .purchase_invoice_items_team .selector-search').first().selector('value', teamId)

      $(lastLineForm).find('.form-field.merchandise .supplier-ref-value').text(itemSupplierReference)
      $(lastLineForm).find('.form-field.merchandise .supplier-ref-block').removeClass('hidden')

      invoiceVatField = $(lastLineForm).find('.form-field .vat-total')

      if itemTaxId
        $(invoiceVatField).val(itemTaxId).change()
      else
        firstVatValue = $(lastLineForm).find('.form-field .vat-total option:first').val()
        $(invoiceVatField).val(firstVatValue).change()

      setTimeout (->
        $('.form-field .invoice-total').trigger('change')), 1000

    # Creates a line BASED on a PurchaseOrder
    _fillPurchaseOrderItem: (lastLineForm, checkboxLine, itemId, itemQuantity, itemConditionning, itemConditionningQuantity) ->
      variantId = $(checkboxLine).find('.variant').attr('data-id')
      variantType = $(checkboxLine).attr('data-variant-type')

      $(lastLineForm).find('.purchase-item-attribute').val(itemId)
      $selectorInput = $(lastLineForm).find('.item-block-role .parcel-item-variant').first()
      $selectorInput.selector('value', variantId, (-> disable_selector_input($selectorInput);$(lastLineForm).find('.form-field .invoice-quantity').trigger('change')))
      $(lastLineForm).find('.hidden.purchase-item-attribute').val(itemId)

      if variantType == "service" || variantType == "cost"
        $(lastLineForm).find('.item-quantifier-population .total-quantity').val(itemQuantity)
        $(lastLineForm).find('.buttons button[data-validate="item-form"]').removeAttr('disabled')
      else
        $(lastLineForm).find('.nested-fields.storing-fields:first .storing-quantifier .storing-quantity').val(itemQuantity)
        $(lastLineForm).find('.nested-fields.storing-fields:first .conditionning-quantity').val(itemConditionningQuantity)
        $(lastLineForm).find('.nested-fields.storing-fields:first .conditionning').val(itemConditionning)

      purchaseOrderLine = $(checkboxLine).closest('.model')
      modelId = $(purchaseOrderLine).find('.model-checkbox').attr('data-id')
      closePurchaseOrderBlock = $(purchaseOrderLine).find('.close-purchase-order')
      if $(closePurchaseOrderBlock).find('input[type="radio"][value="true"]').is(':checked')
        $(lastLineForm).find('.purchase-order-to-close-id').val(modelId)

) ekylibre, jQuery
