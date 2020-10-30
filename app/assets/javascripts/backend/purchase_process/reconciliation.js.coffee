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
    $form = $(event.target).closest('form')
    open_reconciliation_modal($form)

  # Validate modal
  handle_modal_validation = (modal) =>
    modal.getContent().find('.valid-modal').on 'click', (event) ->
      displayedItemIds = $('.nested-fields .nested-item-form[data-item-id]').map(-> $(this).attr('data-item-id')).toArray()
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

  isPurchaseInvoiceForm = ($form) =>
    $form.closest('.simple_form').is('.new_purchase_invoice, .edit_purchase_invoice')

  isReceptionForm = ($form) =>
    $form.closest('.simple_form').is('.new_reception, .edit_reception')

  # Returns a promise that resolves to the content for the modal to be opened
  content_for_reconciliation_modal = ($form) =>
    options = {}
    if isPurchaseInvoiceForm($form)
      options = purchase_invoice_modal_options()
    else if isReceptionForm($form)
      options = reception_modal_options()
    else return Promise.reject("Modal type cannot be guessed!")
    E.ajax.html options

  # Opens the reconciliation modal
  open_reconciliation_modal = ($form) =>
    prom = E.modal.open('#purchase_process_reconciliation', content_for_reconciliation_modal($form))
    prom.then (modal) =>
      content = modal.getContent().get(0)
      root = content.querySelector('.purchase-orders')
      # Attacher un ecouteur evenement sur les checkbox des items
      E.delegateListener root, 'click', ".item-checkbox", (e) =>
        commandContainer = e.target.closest('.model')
        syncState(commandContainer, $form)
        return

      # Handle automated selection of multiple checkbox
      E.delegateListener root, 'click', '.model-checkbox', (e) =>
        checked = e.target.checked
        commandContainer = e.target.closest('.model')
        setAllChildrenTo(commandContainer, checked, $form)
        return

      displayedItemIds = Array.from(document.querySelectorAll('.nested-fields .nested-item-form[data-item-id]'))
      displayedItemIds = displayedItemIds.map((item) => item.dataset.itemId)

      displayedItemIds.forEach (id) =>
        checkbox = content.querySelector(".item input[type='checkbox'][data-id='#{id}']")
        commandContainer = checkbox.closest('.model')
        if checkbox
          checkbox.checked = true
          syncState(commandContainer, $form)
      return

    prom.then (modal) =>
      handle_modal_validation modal

  ##### TOOLS

  # Checks the parent checkbox if all children are checked. Uncheck it if not.
  # If all checked, set 'close command to true, else to false'
  # Also hide/display the close command radio
  syncState = (commandContainer, $form) =>
    itemCheckboxes = Array.from(commandContainer.querySelectorAll('.item-checkbox'))
    allItemsCheckboxesChecked = itemCheckboxes.map((cb) => cb.checked).reduce(((acc, e) => acc && e), true)
    commandContainer.querySelector('.model-checkbox').checked = allItemsCheckboxesChecked

    if isReceptionForm($form)
      setCloseCommand(commandContainer, allItemsCheckboxesChecked)

      closePurchaseOrderBlock = commandContainer.querySelector('.close-purchase-order')
      if itemCheckboxes.map((cb) => cb.checked).includes(true)
        closePurchaseOrderBlock.classList.remove('hidden')
      else
        closePurchaseOrderBlock.classList.add('hidden')

  # Sets the value of the radiobutton to `value`
  setCloseCommand = (commandContainer, value) =>
    closePurchaseOrderBlock = commandContainer.querySelector('.close-purchase-order')
    closePurchaseOrderBlock.querySelector("input[type='radio'][value=#{value}").checked = true

  # Sets all children checkboxes to 'value' and sync state
  setAllChildrenTo = (commandContainer, value, $form) =>
    commandContainer.querySelectorAll('.item-checkbox').forEach((item) => item.checked = value)
    syncState(commandContainer, $form)

  E.reconciliation =
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
        isPurchaseOrderModal = $(itemCheckbox).closest('.modal-content').find('#purchase-orders').val()

        if !displayedItemIds.includes($(itemCheckbox).attr('data-id'))
          E.reconciliation._createNewItemLine(itemCheckbox)

          if index == 0 && isPurchaseOrderModal == "false"
            responsibleId = $(itemCheckbox).closest('.item').attr('data-responsible-id')
            $('#purchase_invoice_responsible_id').first().selector('value', responsibleId)

          E.reconciliation._fillNewLineForm(itemCheckbox, isPurchaseOrderModal)

        if isPurchaseOrderModal == "true"
          $itemCb = $(itemCheckbox)
          purchaseOrderItemId = $itemCb.data('id')
          $formContainer = $("table.list .nested-fields .nested-item-form[data-item-id='#{purchaseOrderItemId}']")
          purchaseOrderToCloseUpdate($itemCb, $formContainer)

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
      itemAnnotation = $(checkboxLine).attr('data-annotation')
      itemCompliantState = $(checkboxLine).attr('data-non-compliant')

      $(lastLineForm).attr('data-item-id', itemId)
      $(lastLineForm).attr('data-non-compliant', itemCompliantState)

      if isPurchaseOrderModal == "true"
        E.reconciliation._fillPurchaseOrderItem(lastLineForm, checkboxLine, itemId, itemQuantity, itemConditionning, itemConditionningQuantity, itemAnnotation)
      else
        E.reconciliation._fillReceptionItem(lastLineForm, checkboxLine, itemId, itemQuantity, itemAnnotation)

      $(lastLineForm).find('input[data-remember="equipment"]').first().val(equipmentId)
      $(lastLineForm).find('input[data-remember="team"]').first().val(teamId)
      $(lastLineForm).find('input[data-remember="project_budget"]').first().val(projectBudgetId)
      $(lastLineForm).find('input[data-remember="activity_budget"]').first().val(activityBudgetId)
      $(lastLineForm).find('.no-reconciliate-item-state').addClass('hidden')
      $(lastLineForm).find('.reconciliate-item-state').removeClass('hidden')
      $line = $(lastLineForm).parent('.nested-fields')
      $line.data('_iceberg').bindSelectorsInitialization ->
        $line.data('_iceberg').setCocoonFormSubmitable()


    # Creates a line BASED on a ReceptionItem
    _fillReceptionItem: (lastLineForm, checkboxLine, itemId, itemQuantity, itemAnnotation) ->
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
      $selectorInput.val(variantId)
      disable_selector_input($selectorInput)

      $(lastLineForm).find('.form-field .invoice-quantity').trigger('change')
      $(lastLineForm).find('.form-field .purchase_invoice_items_activity_budget .selector-search').first().val(activityBudgetId)
      $(lastLineForm).find('.form-field .purchase_invoice_items_team .selector-search').first().val(teamId)
      $(lastLineForm).find('.annotation-logo .annotation-field').trigger('click')
      $(lastLineForm).find('.annotation-section .annotation').val(itemAnnotation)

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
    _fillPurchaseOrderItem: (lastLineForm, checkboxLine, itemId, itemQuantity, itemConditionning, itemConditionningQuantity, itemAnnotation) ->
      variantId = $(checkboxLine).find('.variant').attr('data-id')
      variantType = $(checkboxLine).attr('data-variant-type')

      $(lastLineForm).find('.purchase-item-attribute').val(itemId)

      $selectorInput = $(lastLineForm).find('.item-block-role .parcel-item-variant').first()
      $selectorInput.val(variantId)
      disable_selector_input($selectorInput)

      $(lastLineForm).find('.form-field .invoice-quantity').trigger('change')
      $(lastLineForm).find('.hidden.purchase-item-attribute').val(itemId)
      $(lastLineForm).find('.annotation-logo .annotation-field').trigger('click')
      $(lastLineForm).find('.annotation-section .annotation').val(itemAnnotation)

      if variantType == "service" || variantType == "cost"
        $(lastLineForm).find('.item-quantifier-population .total-quantity').val(itemQuantity)
        $(lastLineForm).find('.buttons button[data-validate="item-form"]').removeAttr('disabled')
      else
        $(lastLineForm).find('.nested-fields.storing-fields:first .storing-quantifier .storing-quantity').val(itemQuantity)
        $(lastLineForm).find('.nested-fields.storing-fields:first .conditionning-quantity').val(itemConditionningQuantity)
        $(lastLineForm).find('.nested-fields.storing-fields:first .conditionning').val(itemConditionning)

  # Given checkbox and formContainer, this method sets the purchase-order-to-close-id property to the purchase order id on the given reception item's form fields
  #    if the purchase order of the selected element is marked for closure when saving the reception
  #
  # @param [jQuery<HTMLElement>] checkbox %li containing a checkbox for an item to maybereconcile
  # @param [jQuery<HTMLElement>] formContainer form line containing information about a reception item
  purchaseOrderToCloseUpdate = ($checkbox, $formContainer) ->
    $purchaseOrderLine = $checkbox.closest('.model')
    modelId = $purchaseOrderLine.find('.model-checkbox').attr('data-id')
    $closePurchaseOrderBlock = $purchaseOrderLine.find('.close-purchase-order')
    if $closePurchaseOrderBlock.find('input[type="radio"][value="true"]').is(':checked')
      $formContainer.find('.purchase-order-to-close-id').val(modelId)

  E.onElementDetected 'new_reception', (form) =>
    urlParams = new URLSearchParams(window.location.search)
    if urlParams.has('purchase_order_ids')
      open_reconciliation_modal $(form)

  E.onElementDetected 'new_purchase_invoice', (form) =>
    urlParams = new URLSearchParams(window.location.search)
    if urlParams.has('reception_ids')
      open_reconciliation_modal $(form)


) ekylibre, jQuery
