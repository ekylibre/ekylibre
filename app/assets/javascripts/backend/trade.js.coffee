((E, $) ->
  'use strict'

  # Toggle annotation widget
  $(document).on "click", "a[data-annotate]", (event) ->
    link = $(this)
    scope = $("html")
    if link.data("use-closest")
      scope = link.closest(link.data("use-closest"))
    link.hide()
    annotation = scope.find(link.data('annotate'))
    annotation.show()
    autosize annotation.find("textarea").focus()
    return false


  # Manage fields filling in sales/purchases
  $(document).on "selector:change", "*[data-variant-of-deal-item]", ->
    element = $(this)
    options = element.data("variant-of-deal-item")
    variant_id = element.selector('value')
    reg = new RegExp("\\bRECORD_ID\\b", "g")
    if variant_id?
      item = element.closest("*[data-trade-item]")
      $.ajax
        url: options.url.replace(reg, variant_id)
        dataType: "json"
        success: (data, status, request) ->
          # Update fields
          if data.name
            item.find(options.label_field or ".label").val(data.name)

          if data.depreciable
            item.addClass("with-fixed-asset")
          else
            item.removeClass("with-fixed-asset")

          if unit = data.unit
            if unit.name
              item.find(options.unit_name_tag or ".unit-name").html(data.name)

            input = item.find(options.unit_pretax_amount_field or "*[data-trade-component='unit_pretax_amount']")
            if unit.pretax_amount isnt undefined
              input.val(unit.pretax_amount)
            else if input.val() is ""
              input.val(0)

            input = item.find(options.unit_amount_field or "*[data-trade-component='unit_amount']")
            if unit.amount isnt undefined
              input.val(unit.amount)
            else if input.val() is ""
              input.val(0)

          if data.tax_id?
            item.find(options.tax or "*[data-trade-component='tax']").val(data.tax_id)
          # Compute totals
          E.trade.updateUnitPretaxAmount(item)

        error: (request, status, error) ->
          console.log("Error while retrieving price and tax fields content: #{error}")
    else
      console.warn "Cannot get variant ID"


  E.trade =

    round: (value, digits) ->
      magnitude = Math.pow(10, digits)
      console.log value, magnitude, value * magnitude, Math.round(value * magnitude), (Math.round(value * magnitude) / magnitude), (Math.round(value * magnitude) / magnitude).toFixed(digits)
      return (Math.round(value * magnitude) / magnitude).toFixed(digits)

    # Compute other amounts from unit pretax amount
    updateUnitPretaxAmount: (item) ->
      values = E.trade.itemValues(item)
      updates = {}
      # Compute pretax_amount
      updates.pretax_amount = values.unit_pretax_amount * values.quantity * (100.0 - values.reduction_percentage) / 100.0
      # Compute amount
      updates.amount = E.trade.round(updates.pretax_amount * values.tax, 2)
      # Round pretax amount
      updates.pretax_amount = E.trade.round(updates.pretax_amount, 2)
      E.trade.itemValues(item, updates)

    # Compute other amounts from pretax amount
    updatePretaxAmount: (item) ->
      values = E.trade.itemValues(item)
      updates = {}
      # Compute unit_pretax_amount
      updates.unit_pretax_amount = E.trade.round(values.pretax_amount / (values.quantity * (100.0 - values.reduction_percentage) / 100.0), 4)
      # Compute amount
      updates.amount = E.trade.round(values.pretax_amount * values.tax, 2)
      E.trade.itemValues(item, updates)

    # Compute other amounts from amount
    updateAmount: (item) ->
      values = E.trade.itemValues(item)
      updates = {}
      # Compute pretax_amount
      updates.pretax_amount = values.amount / values.tax
      # Compute unit_pretax_amount
      updates.unit_pretax_amount = E.trade.round(updates.pretax_amount / (values.quantity * (100.0 - values.reduction_percentage) / 100.0), 4)
      # Round pretax amount
      updates.pretax_amount = E.trade.round(updates.pretax_amount, 2)
      E.trade.itemValues(item, updates)

    # Compute other amounts from amount
    updateCreditedQuantity: (item) ->
      values = E.trade.itemValues(item)
      updates = {}
      # Compute pretax_amount
      updates.pretax_amount = -1 * values.unit_pretax_amount * values.credited_quantity * (100.0 - values.reduction_percentage) / 100.0
      # Compute unit_pretax_amount
      updates.amount = E.trade.round(updates.pretax_amount * values.tax, 2)
      # Round pretax amount
      updates.pretax_amount = E.trade.round(updates.pretax_amount, 2)
      E.trade.itemValues(item, updates)

    find: (item, name) ->
      item.find("*[data-trade-component='#{name}']")

    itemValues: (item, updates = null) ->
      if updates is null
        values =
          unit_pretax_amount: E.trade.find(item, "unit_pretax_amount").numericalValue()
          quantity: E.trade.find(item, "quantity").numericalValue()
          credited_quantity: E.trade.find(item, "credited_quantity").numericalValue()
          reduction_percentage: E.trade.find(item, "reduction_percentage").numericalValue()
          tax: E.trade.find(item, "tax").numericalValue()
          pretax_amount: E.trade.find(item, "pretax_amount").numericalValue()
          amount: E.trade.find(item, "amount").numericalValue()
        return values
      else
        for key, value of updates
          E.trade.find(item, key).numericalValue(value)

  E.purchasing =

    # Compute what have to be computed
    compute: (item, changedComponent) ->
      component = changedComponent.data("trade-component")
      switch component
        when 'unit_pretax_amount', 'quantity', 'reduction_percentage', 'tax'
          E.trade.updateUnitPretaxAmount(item)
        when 'pretax_amount'
          E.trade.updatePretaxAmount(item)
        when 'amount'
          # Do nothing. Ability to customize precisely amount
        else
          console.error "Unknown component: #{component}"

  # Computes changes on items
  $(document).on "keyup change", "form *[data-trade-item='purchasing'] *[data-trade-component]", (event) ->
    component = $(this)
    E.purchasing.compute component.closest("*[data-trade-item]"), component

  E.selling =

    # Compute what have to be computed
    compute: (item, changedComponent) ->
      component = changedComponent.data("trade-component")
      switch component
        when 'unit_pretax_amount', 'quantity', 'reduction_percentage', 'tax'
          E.trade.updateUnitPretaxAmount(item)
        when 'pretax_amount'
          E.trade.updatePretaxAmount(item)
        when 'amount'
          E.trade.updateAmount(item)
        else
          console.error "Unknown component: #{component}"

  # Computes changes on items
  $(document).on "keyup change", "form *[data-trade-item='selling'] *[data-trade-component]", (event) ->
    component = $(this)
    E.selling.compute component.closest("*[data-trade-item]"), component


  # Crediting workflow
  E.crediting =
    # Compute what have to be computed
    compute: (item, changedComponent) ->
      component = changedComponent.data("trade-component")
      switch component
        when 'credited_quantity'
          E.trade.updateCreditedQuantity(item)
        else
          console.error "Unknown component: #{component}"

  # Computes changes on items
  $(document).on "keyup change", "form *[data-trade-item='crediting'] *[data-trade-component]", (event) ->
    component = $(this)
    E.crediting.compute component.closest("*[data-trade-item]"), component

  return
) ekylibre, jQuery
