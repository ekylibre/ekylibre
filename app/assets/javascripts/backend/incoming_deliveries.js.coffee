((E, $) ->
  'use strict'


  # Set scope for purchase
  $(document).on "selector:change", "*[data-delivery-purchase]", (event)->
    select = $(this)
    form = select.closest("form")
    entity_id = select.selector('value')
    purchase = form.find('#incoming_parcel_purchase_id').first()
    url = "/backend/purchases/unroll?working=true"
    purchase_id = purchase.selector('value')
    if purchase_id
      url += "&scope[current_or_self]=#{purchase_id}"
    else
      url += "&scope[current]=true"
    if entity_id
      url += "&scope[of_supplier]=#{entity_id}"
    purchase.attr("data-selector", url)
    purchase.data("selector", url)

) ekylibre, jQuery
