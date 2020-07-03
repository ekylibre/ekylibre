((E, $) ->
  'use strict'

  toggleNewReceptionButton = () ->
    $newParcelBtn = $('#generate-parcel-btn')
    newParcelUrl = $newParcelBtn.prop('href')

    $(document).on 'change', 'input[data-list-selector]', ->
      selectedOrders = $('input[data-list-selector]:checked').filter ->
                         /\d/.test($(this).data('list-selector'))
      selectedOrdersIds = selectedOrders.map ->
                            $(this).data('list-selector')
                          .toArray()
      selectedOrdersSupplierIds = selectedOrders.map ->
                                    $(this).closest('tr').data().supplierId
                                  .toArray()
      reconciledOrders = selectedOrders.filter ->
                            $(this).closest('tr').data('reconciliation-state') == 'reconcile'

      sameSupplier = _.uniq(_.compact(selectedOrdersSupplierIds)).length == 1

      if selectedOrdersIds.length > 0
        $newParcelBtn.prop('href', "#{newParcelUrl}?mode=prefilled&purchase_order_ids=#{selectedOrdersIds}")
      else
        $newParcelBtn.prop('href', newParcelUrl)

      disabled = !selectedOrders.length || reconciledOrders.length || !sameSupplier
      # !! so we're sure disabled is a Boolean and not just truthy/falsy — for jQuery
      $newParcelBtn.toggleClass('disabled', !!disabled)

  $(document).ready ->
    toggleNewReceptionButton() if $('#purchase_orders-list, #unreceived_purchase_orders-list').length > 0

) ekylibre, jQuery
