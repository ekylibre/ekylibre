((E, $) ->
  'use strict'
  PURCHASE_PROCESS_FORM = '#new_reception, #new_purchase_invoice, .edit_reception, .edit_purchase_invoice'

  # Initialization of helpers for reconciliation badges
  $ =>
    E.reconciliation.incident_badge = new StateBadgeSet('#incident-badge')
    E.reconciliation.badges = new StateBadgeSet('#reconciliation-badges')
    E.reconciliation.state = new StateSet('.reconciliable-form', "reconciliable-form")

  # Change reconciliation badges state
  set_reconciliation_state = (is_reconciled) =>
    if is_reconciled
      E.reconciliation.badges.setState 'reconcile'
      E.reconciliation.state.setState 'reconcile'
    else
      E.reconciliation.badges.setState 'to-reconcile'
      E.reconciliation.state.setState 'to-reconcile'

  # Change incident badge state
  set_incident_state = (is_incident) =>
    if is_incident
      E.reconciliation.incident_badge.setState 'incident'
    else
      E.reconciliation.incident_badge.setState null

  # Update nested items styles based on their compliance state (incident)
  handle_form_item_non_compliant = ($nested_fields, $input) =>
    $input ||= $nested_fields.find('.reception-item-non-compliant')
    if $input.is(':checked')
      $nested_fields.addClass('reception-form__nested-fields--invalid')
    else
      $nested_fields.removeClass('reception-form__nested-fields--invalid')

  # Handles non-compliance for late delivery checkbox in receptions
  $(document).on 'change', '#reception_late_delivery', ->
    $container = $(this).closest('.reception-form')
    if $(this).is(':checked')
      $container.addClass('reception-form--late')
    else
      $container.removeClass('reception-form--late')
    refresh_state()

  # Handle non-compliance 'local' update for nested items
  $(document).on 'change', '.reception-item-non-compliant', -> handle_form_item_non_compliant($(this).closest('tbody.nested-fields'), $(this))

  # Updates state for badges (reconciliation and incident)
  refresh_state = =>
    set_reconciliation_state !!$('.nested-fields .nested-item-form[data-item-id]').length
    set_incident_state !!$(".reception-form--late, .reception-form__nested-fields--invalid").length

  # Disable selector (unroll) component
  disable_selector_input = ($selector_input) =>
    $selector_input.prop('disabled', true)
    $selector_input.siblings(':last').addClass('disabled')

  # Disable selector (unroll) component for variant in a nested-item-form for reconciliated items
  prevent_unroll_edition_for_reconciliated_items = (e, data) =>
    target = data if data
    target ||= e.target
    target = $(target).closest('tbody') unless $(target).is('tbody')

    if $(target).find('.nested-item-form[data-item-id]').length
      disable_selector_input $(target).find('input[id*="variant"]')

  $(document).on 'cocoon:after-insert', PURCHASE_PROCESS_FORM, prevent_unroll_edition_for_reconciliated_items
  $(document).on 'cocoon:after-remove', PURCHASE_PROCESS_FORM, refresh_state

  # Update incident status (badge) after nested item form validation
  $(document).on 'iceberg:cancelled iceberg:validated', (event, data) =>
    handle_form_item_non_compliant data.line
    refresh_state()

  ##############################
  #    Reconciliation modal    #
  ##############################
  # Open modal on button click
  $(document).on 'click', '#showReconciliationModal', (event) =>
    open_reconciliation_modal event

  # Handle automated selection of multiple checkbox
  $(document).on 'change', '#purchase_process_reconciliation .model-checkbox', (event) =>
    checked = $(event.target).is(':checked')
    $(event.target).closest('.model').find('.item-checkbox').prop('checked', checked)
    E.reconciliation.displayClosePurchaseOrderBlock(event)

  # Checkbox selection
  $(document).on 'change', '#purchase_process_reconciliation .item-checkbox', (event) =>
    E.reconciliation.displayClosePurchaseOrderBlock(event)

  # Validate modal
  handle_modal_validation = (modal) =>
    modal.getContent().find('.valid-modal').on 'click', (event) ->
      displayedItemIds = $('.nested-fields .nested-item-form[data-item-id]').map(-> $(this).attr('data-item-id')).toArray()
      if $(this).attr('data-item-reconciliation') != undefined
        # Reconciliation on line
        E.reconciliation.reconciliateItems(modal.getContent())
        itemCheckbox = modal.getContent().find('.item-checkbox:checked')
        isPurchaseOrderModal = $('#purchase-orders').val()
        E.reconciliation._fillNewLineForm(itemCheckbox, isPurchaseOrderModal)
      else
        # Reconciliation on form
        E.reconciliation.createLinesWithSelectedItems(modal.getContent(), displayedItemIds, event)
        E.reconciliation.removeLineWithUnselectedItems(modal.getContent(), displayedItemIds, event)

      refresh_state()
      modal.close()

  purchase_invoice_modal_options = =>
    url = "/backend/purchase_process/reconciliation/receptions_to_reconciliate"
    data = supplier: $('input[name="purchase_invoice[supplier_id]"]').val()
    $form = $('.edit_purchase_invoice')
    if $form.length
      action = $form.attr('action')
      data['purchase_invoice'] = action.substr(action.lastIndexOf('/') + 1)
    {url: url, data: data}

  reception_modal_options = =>
    url = "/backend/purchase_process/reconciliation/purchase_orders_to_reconciliate"
    data = supplier: $('input[name="reception[sender_id]"]').val()
    $form = $('.edit_reception')
    if $form.length
      action = $form.attr('action')
      data['reception'] = action.substr(action.lastIndexOf('/') + 1)
    {url: url, data: data}

  # Returns a promise that resolves to the content for the modal to be opened
  content_for_reconciliation_modal = (event) =>
    isPurchaseInvoiceForm = $(event.target).closest('.simple_form').is('.new_purchase_invoice, .edit_purchase_invoice')
    isReceptionForm = $(event.target).closest('.simple_form').is('.new_reception, .edit_reception')

    options = {}
    if isPurchaseInvoiceForm
      options = purchase_invoice_modal_options()
    else if isReceptionForm
      options = reception_modal_options()
    else return Promise.reject("Modal type cannot be guessed!")
    E.ajax.html options

  # Opens the reconciliation modal
  open_reconciliation_modal = (event) =>
    prom = E.modal
      .open('#purchase_process_reconciliation', content_for_reconciliation_modal(event))
    prom.then (modal) =>
      displayedItemIds = $('.nested-fields .nested-item-form[data-item-id]').map(-> $(this).attr('data-item-id')).toArray()
      for id in displayedItemIds
        $checkbox = modal.getModalContent().find("input[type='checkbox'][data-id=#{id}]")
        $checkbox.prop('checked', true) if $checkbox.length
    prom.then (modal) =>
      handle_modal_validation modal


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

    reconciliateItems: (modalContent) ->
      checkedItemId = modalContent.find('.item-checkbox:checked').attr('data-id')
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
        $checkbox = $(modal).find(".item-checkbox[data-id=#{id}]")
        if $checkbox.length && !$checkbox.prop('checked')
          $container = $(".nested-fields .nested-item-form[data-item-id='#{id}']").closest('tbody')
          if $container.length
            $container.find('a.remove-item').click()
      return

    _createNewItemLine: (itemCheckbox) ->
      variantType = $(itemCheckbox).closest('.item').attr('data-variant-type')

      $buttonToClick = switch variantType
        when 'service' then $('.row-footer .add-service')
        when 'cost' then $('.row-footer .add-fees')
        else
          $('.row-footer .add-merchandise')

      $buttonToClick.find('.add_fields').trigger('click')

    _fillNewLineForm: (itemCheckbox, isPurchaseOrderModal) ->
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
      else
        E.reconciliation._fillReceptionItem(lastLineForm, checkboxLine, itemId, itemQuantity)

      $(lastLineForm).find('input[data-remember="equipment"]').first().selector('value', equipmentId)
      $(lastLineForm).find('input[data-remember="team"]').first().selector('value', teamId)
      $(lastLineForm).find('input[data-remember="project_budget"]').first().selector('value', projectBudgetId)
      $(lastLineForm).find('input[data-remember="activity_budget"]').first().selector('value', activityBudgetId)
      $(lastLineForm).find('.no-reconciliate-item-state').addClass('hidden')
      $(lastLineForm).find('.reconciliate-item-state').removeClass('hidden')
      $line = $(lastLineForm).parent('.nested-fields')
      $line.data('_iceberg').bindSelectorsInitialization ->
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
