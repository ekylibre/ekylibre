# allows price and tax auto filling in sales view

(($) ->
  'use strict'

  # Manage fields filling in sales
  $(document).on "selector:change", "*[data-variant-of-deal-item]", ->
    element = $(this)
    options = element.data("variant-of-deal-item")
    variant_id = element.selector('value')
    reg = new RegExp("\\bRECORD_ID\\b", "g")
    if variant_id?
      row = element.closest(options.scope or ".nested-fields")
      $.ajax
        url: options.url.replace(reg, variant_id)
        dataType: "json"
        success: (data, status, request) ->
          # Update fields
          if data.name
            row.find(options.label_field or ".label").val(data.name)

          console.log data.depreciable
          if data.depreciable
            row.addClass("with-fixed-asset")
          else
            row.removeClass("with-fixed-asset")

          if unit = data.unit
            if unit.name
              row.find(options.unit_name_tag or ".unit-name").html(data.name)

            if unit.pretax_amount
              row.find(options.unit_pretax_amount_field or ".unit-pretax-amount").val(unit.pretax_amount)
            else if !unit.pretax_amount
              row.find(options.unit_pretax_amount_field or ".unit-pretax-amount").val(0)

            if unit.amount
              row.find(options.unit_amount_field or ".unit-amount").val(unit.amount)
            else if !unit.amount
              row.find(options.unit_amount_field or ".unit-amount").val(0)

          if data.tax_id?
            row.find(options.tax or ".tax").val(data.tax_id)
        error: (request, status, error) ->
          console.log("Error while retrieving price and tax fields content: #{error}")
    else
      console.warn "Cannot get variant ID"

  $(document).on "change emulated:change keyup", ".nested-fields .unit-pretax-amount", ->
    element = $(this)
    row = element.closest(".nested-fields")
    row.find(".all-taxes-included").val(0)
    rate = row.find(".tax").find(":selected").data("rate")
    row.find(".unit-amount").val((element.numericalValue() * rate).toFixed(2))

  $(document).on "change emulated:change keyup", ".nested-fields .tax", ->
    element = $(this)
    row = element.closest(".nested-fields")
    rate = row.find(".tax").find(":selected").data("rate")
    console.log row.find(".all-taxes-included").val()
    if row.find(".all-taxes-included").val() == "1"
      row.find(".unit-pretax-amount").val((row.find(".unit-amount").numericalValue() / rate).toFixed(2))
    else
      row.find(".unit-amount").val((row.find(".unit-pretax-amount").numericalValue() * rate).toFixed(2))

  $(document).on "change emulated:change keyup", ".nested-fields .unit-amount", ->
    element = $(this)
    row = element.closest(".nested-fields")
    row.find(".all-taxes-included").val(1)
    rate = row.find(".tax").find("option:selected").data("rate")
    row.find(".unit-pretax-amount").val (element.val() / rate).toFixed(2)

  # $(document).on "change emulated:change keyup", ".reduced-unit-pretax-amount", ->
  #   console.log "ok"
  #   element = $(this)
  #   row = element.closest(".nested-fields")
  #   quantity = row.find(".quantity").val()
  #   row.find(".amount") = element.val() * quantity
  #   if unit_amount = row.find(".unit-amount") and tax = row.find(".tax")
  #     rate = tax.find(":selected").data("rate")
  #     unit_amount.val (element.val() * rate).toFixed(2)
  #   if reduction = row.find(".reduction") and reduced = row.find(".reduced-pretax-unit-amount")
  #     rate = (100 - (reduction.val() ? 0)) / 100
  #     reduced.val (element.val() * rate).toFixed(2)
  #     reduced.fire("emulated:change")


  return
) jQuery
