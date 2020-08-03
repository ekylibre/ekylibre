((E, $) ->
  'use strict'

  listControlledBtn =
    toggleNewInvoiceButton: () ->
      $btn = if $('#generate-invoice-btn button').length then $('#generate-invoice-btn button') else $('#generate-invoice-btn a')
      linksUrls = $('#generate-invoice-btn a').map -> { element: $(this), url: $(this).prop('href') }
      @_bindInputs('reception', 'sender', $btn, linksUrls)

    toggleNewReceptionButton: () ->
      $btn = $('#generate-parcel-btn')
      linksUrls = [{ element: $btn, url: $btn.prop('href') }]
      @_bindInputs('purchase_order', 'supplier', $btn, linksUrls)

    _bindInputs: (model, third, $btn, linksUrls) ->
      $(document).on 'change', 'input[data-list-selector]', =>
        $selectedItems = @_getSelectedItems()
        selectedItemsIds = @_getSelectedItemsIds($selectedItems)
        $reconciledItems = @_getReconciledItems($selectedItems)
        $draftItems = @_getDraftItems($selectedItems)
        sameThird = @_checkThirdUniqueness($selectedItems, third)
        @_setBtnUrl(selectedItemsIds, $btn, model, linksUrls)
        @_setDisabledProp(model, $btn, $selectedItems, $reconciledItems, $draftItems, sameThird)

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

    _getDraftItems: ($selectedItems) ->
      $selectedItems.filter ->
        $(this).closest('tr').data('state') == 'draft'

    _checkThirdUniqueness: ($selectedItems, third) ->
      selectedItemsThirdIds = $selectedItems.map ->
                                $(this).closest('tr').data("#{third}Id")
                              .toArray()

      _.uniq(_.compact(selectedItemsThirdIds)).length == 1

    _setBtnUrl: (selectedItemsIds, $btn, model, linksUrls) ->
      urlSeparator = if $btn.hasClass('dropdown-toggle') then '&' else '?'

      for linkUrl in linksUrls
        if selectedItemsIds.length > 0
          $(linkUrl.element).prop('href', "#{linkUrl.url}#{urlSeparator}mode=prefilled&#{model}_ids=#{selectedItemsIds}")
        else
          $(linkUrl.element).prop('href', linkUrl.url)

    _setDisabledProp: (model, $btn, $selectedItems, $reconciledItems, $draftItems, sameThird) ->
      disabled = if model == 'reception'
        !$selectedItems.length || !sameThird || $draftItems.length
      else if model == 'purchase_order'
        !$selectedItems.length || $reconciledItems.length || !sameThird

      $btn.toggleClass('disabled', !!disabled)

  $(document).ready ->
    listControlledBtn.toggleNewReceptionButton() if $('#purchase_orders-list, #unreceived_purchase_orders-list').length > 0
    listControlledBtn.toggleNewInvoiceButton() if $('#receptions-list').length > 0

) ekylibre, jQuery
