((E, $) ->
  'use strict'

  listControlledBtn =
    toggleNewInvoiceButton: () ->
      $btn = $('#generate-invoice-btn').find('a')
      url = $btn.prop('href')
      @_bindInputs('reception', 'sender', $btn, url)

    toggleNewReceptionButton: () ->
      $btn = $('#generate-parcel-btn')
      url = $btn.prop('href')
      @_bindInputs('purchase_order', 'supplier', $btn, url)

    _bindInputs: (model, third, $btn, url) ->
      $(document).on 'change', 'input[data-list-selector]', =>
        $selectedItems = @_getSelectedItems()
        selectedItemsIds = @_getSelectedItemsIds($selectedItems)
        $reconciledItems = @_getReconciledItems($selectedItems)
        sameThird = @_checkThirdUniqueness($selectedItems, third)
        @_setBtnUrl(selectedItemsIds, $btn, model, url)
        @_setDisabledProp(model, $btn, $selectedItems, $reconciledItems, sameThird)

    _getSelectedItems: () ->
      $('input[data-list-selector]:checked').filter ->
        /\d/.test($(this).data('list-selector'))

    _getSelectedItemsIds: ($selectedItems) ->
      $selectedItems.map ->
        $(this).data('list-selector')
      .toArray()

    _getReconciledItems: ($selectedItems) ->
      $selectedItems.filter ->
        $(this).closest('tr').data('reconciliation-state') == 'reconcile'

    _checkThirdUniqueness: ($selectedItems, third) ->
      selectedItemsThirdIds = $selectedItems.map ->
                                $(this).closest('tr').data("#{third}Id")
                              .toArray()

      _.uniq(_.compact(selectedItemsThirdIds)).length == 1

    _setBtnUrl: (selectedItemsIds, $btn, model, url) ->
      if selectedItemsIds.length > 0
        $btn.prop('href', "#{url}?mode=prefilled&#{model}_ids=#{selectedItemsIds}")
      else
        $btn.prop('href', url)

    _setDisabledProp: (model, $btn, $selectedItems, $reconciledItems, sameThird) ->
      disabled = if model == 'reception'
        !$selectedItems.length || !sameThird
      else if model == 'purchase_order'
        !$selectedItems.length || $reconciledItems.length || !sameThird

      $btn.toggleClass('disabled', !!disabled)

  $(document).ready ->
    listControlledBtn.toggleNewReceptionButton() if $('#purchase_orders-list, #unreceived_purchase_orders-list').length > 0
    listControlledBtn.toggleNewInvoiceButton() if $('#receptions-list').length > 0

) ekylibre, jQuery
