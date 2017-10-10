((E, $) ->
  'use strict'

  $(document).ready ->
    if $('#purchase_process_reconciliation').length > 0
      $('#main .heading-toolbar').addClass('purchase-process-reconciliation')

  $(document).on 'change', '#purchase_process_reconciliation .model-checkbox', (event) ->
    checked = $(event.target).is(':checked')
    $(event.target).closest('.model').find('.item-checkbox').prop('checked', checked)

  $(document).on 'click', '#purchase_process_reconciliation .valid-modal', (event) ->
    modal = $(event.target).closest('#purchase_process_reconciliation')
    modelsCheckboxes = $(modal).find('.model-checkbox:checked')
    itemsCheckboxes = $(modal).find('.item-checkbox:checked')

    purchasesAttributesIds = []
    $(modelsCheckboxes).map (index, checkbox) =>
      purchasesAttributesIds.push({id: $(checkbox).attr('data-id')})

    purchasesItemsAttributesIds = []
    $(itemsCheckboxes).map (index, checkbox) =>
      purchasesItemsAttributesIds.push({id: $(checkbox).attr('data-id')})

    jsonPurchasesAttributes = JSON.stringify(purchasesAttributesIds)
    jsonPurchasesItemsAttributes = JSON.stringify(purchasesItemsAttributesIds)

    purchasesAttributes = $('<input type="hidden" class="purchases-attributes" name="reception[purchases_attributes]" value="' + jsonPurchasesAttributes + '"/>')
    purchasesItemsAttributes = $('<input type="hidden" class="purchase-items-attributes" name="reception[purchase_items_attributes]" value="' + jsonPurchasesItemsAttributes + '"/>')

    $('.simple_form').prepend(purchasesAttributes)
    $('.simple_form').prepend(purchasesItemsAttributes)

    if $(modelsCheckboxes).length > 0 || $(itemsCheckboxes).length > 0
      $('.purchase-process-reconciliation .no-reconciliate-title').addClass('hidden')
      $('.no-reconciliate-state').addClass('hidden')

      $('.purchase-process-reconciliation .reconcile-title').removeClass('hidden')
      $('.reconcile-state').removeClass('hidden')

      $('.reconciliate-state').addClass('hidden')


    @reconciliationModal= new ekylibre.modal('#purchase_process_reconciliation')
    @reconciliationModal.getModal().modal 'hide'

) ekylibre, jQuery
