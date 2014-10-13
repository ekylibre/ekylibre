# allows price and tax auto filling in sales view

(($) ->
  'use strict'

  # Manage fields filling in sales
  $(document).on "selector:change", "*[data-priced-item]", ->
    # Get json info on priced item
    element = $(this)
    options = element.data("priced-item")
    price_id = element.selector('value')
    reg = new RegExp("\\bPRICE_ID\\b", "g")
    if price_id?
      $.ajax options.url.replace(reg, price_id),
        dataType: "json"
        success: (data, status, request) ->
          # Update fields
          row = element.closest(options.scope or "body")
          row.find(options.amount or ".amount").val(data.amount)
          if data.reference_tax_id?
            row.find(options.tax or ".tax").val(data.reference_tax_id)
        error: (request, status, error) ->
          console.log("Error while retrieving price and tax fields content: #{error}")

  # Manage fields filling in purchases
  $(document).on "click selector:change", "*[data-priced-variant]", ->
    # Get json info on priced variant
    element = $(this)
    options = element.data("priced-variant")
    variant_id = element.selector('value')
    # supplier_id = $("#purchase_supplier_id")[0].selector('value')
    reg = new RegExp("\\bVARIANT_ID\\b", "g")
    if variant_id?
      $.ajax options.url.replace(reg, variant_id),
        dataType: "json"
        # data: "{supplier_id: #{supplier_id}}"
        success: (data, status, request) ->
          # Update fields
          row = element.closest(options.scope or "body")
          row.find(options.amount or ".amount").val(data.pretax_amount)
          if data.tax_id?
            row.find(options.tax or ".tax").val(data.tax_id)
        error: (request, status, error) ->
          console.log("Error while retrieving price and tax fields content: #{error}")

  return
) jQuery
