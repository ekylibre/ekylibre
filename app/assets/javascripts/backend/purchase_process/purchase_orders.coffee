((E, $) ->
  'use strict'

  $(document).ready ->
    $('#purchase_orders-list').each ->
      $newParcelBtn = $('#generate-parcel-btn')
      newParcelUrl = $newParcelBtn.prop('href')

      $(document).on 'change', 'input[data-list-selector]', ->
        selectedOrders = $('input[data-list-selector]:checked').filter ->
                           /\d/.test($(this).data('list-selector'))
        selectedOrdersIds = selectedOrders.map ->
                              $(this).data('list-selector')
                            .toArray()
        reconciledOrders = selectedOrders.filter ->
                             $(this).closest('tr').data('reconciliation-state') == 'reconcile'

        if selectedOrdersIds.length > 0
          $newParcelBtn.prop('href', "#{newParcelUrl}?mode=prefilled&purchase_order_ids=#{selectedOrdersIds}")
        else
          $newParcelBtn.prop('href', newParcelUrl)
         
        disabled = !selectedOrders.length || reconciledOrders.length
        # !! so we're sure disabled is a Boolean and not just truthy/falsy — for jQuery 
        $newParcelBtn.toggleClass('disabled', !!disabled)

  $(document).ready ->
    $('#unreceived_purchase_orders-list').each ->
      $newParcelBtn = $('#generate-parcel-btn')
      newParcelUrl = $newParcelBtn.prop('href')

      $(document).on 'change', 'input[data-list-selector]', ->
        selectedOrders = $('input[data-list-selector]:checked').filter ->
                           /\d/.test($(this).data('list-selector'))
        selectedOrdersIds = selectedOrders.map ->
                              $(this).data('list-selector')
                            .toArray()
        reconciledOrders = selectedOrders.filter ->
                             $(this).closest('tr').data('reconciliation-state') == 'reconcile'

        if selectedOrdersIds.length > 0
          $newParcelBtn.prop('href', "#{newParcelUrl}?mode=prefilled&purchase_order_ids=#{selectedOrdersIds}")
        else
          $newParcelBtn.prop('href', newParcelUrl)
         
        disabled = !selectedOrders.length || reconciledOrders.length
        # !! so we're sure disabled is a Boolean and not just truthy/falsy — for jQuery 
        $newParcelBtn.toggleClass('disabled', !!disabled)

) ekylibre, jQuery
