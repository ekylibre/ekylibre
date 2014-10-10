# allows price and tax auto filling in sales view

(($) ->
  'use strict'
  $(document).on "load click change emulated:change", "*[data-priced-item]", ->
    # get json info on priced item
    options = $(this).data("priced-item")
    element = $(this)
    price_id = element.selector('value')
    reg = new RegExp("\\bPRICE_ID\\b", "g")
    if price_id?
      $.ajax options.url.replace(reg, price_id),
        dataType: "json"
        success: (data, status, request) ->
          # update fields
          row = element.closest(options.scope or "body")
          row.find(options.amount or ".amount").val(data.amount)
          if data.reference_tax_id?
            row.find(options.tax or ".tax").val(data.reference_tax_id)
        error: (request, status, error) ->
          console.log("Error while retrieving price and tax fields content: #{error}")
  return
) jQuery
