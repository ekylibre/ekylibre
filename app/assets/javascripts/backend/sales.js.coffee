# allows price and tax auto filling in sales view

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
    annotation.find("textarea").focus()
    return false


  # Manage fields filling in sales/purchases
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

  E.trade =
    # CSS class for reference fields
    referenceClass: "special"

    methods:
      computeManual: (item, changedComponent) ->
        console.log "Compute Manual method from #{changedComponent}"
        # Do nothing for now

      computeQuantityTax: (item, changedComponent) ->
        console.log "Compute Quantity-Tax method from #{changedComponent}"
        if changedComponent == "amount"
          E.trade.ops.mmma(item)
          E.trade.ops.mmmb(item)
          E.trade.ops.mmmc(item)
        else if changedComponent == "pretax_amount"
          E.trade.ops.mmmd(item)
          E.trade.ops.mmmb(item)
          E.trade.ops.mmmc(item)
        else if changedComponent == "unit_amount"
          E.trade.ops.mmme(item)
          E.trade.ops.mmmg(item)
          E.trade.ops.mmmd(item)
        else if changedComponent == "unit_pretax_amount"
          E.trade.ops.mmmf(item)
          E.trade.ops.mmmg(item)
          E.trade.ops.mmmd(item)
        else
          console.error "Cannot compute anything for #{changedComponent}"

      computeTaxQuantity: (item, changedComponent) ->
        console.log "Compute Tax-Quantity method from #{changedComponent}"
        if changedComponent == "amount"
          E.trade.ops.mmmb(item)
          E.trade.ops.mmme(item)
          E.trade.ops.mmmg(item)
        else if changedComponent == "pretax_amount"
          E.trade.ops.mmmc(item)
          E.trade.ops.mmmf(item)
          E.trade.ops.mmmh(item)
        else if changedComponent == "unit_amount"
          E.trade.ops.mmmh(item)
          E.trade.ops.mmme(item)
          E.trade.ops.mmmg(item)
        else if changedComponent == "unit_pretax_amount"
          E.trade.ops.mmmg(item)
          E.trade.ops.mmmf(item)
          E.trade.ops.mmmh(item)
        else
          console.error "Cannot compute anything for #{changedComponent}"

      computeAdaptive: (item, changedComponent) ->
        adaptativeMethod = item.prop("adaptativeMethod")
        if adaptativeMethod == "tax_quantity"
          E.trade.methods.computeTaxQuantity(item, changedComponent)
        else if adaptativeMethod == "quantity_tax"
          E.trade.methods.computeQuantityTax(item, changedComponent)
        # Evaluate if re-computation is needed
        amount = E.trade.find("unit_pretax_amount", item)
        tax = E.trade.find("tax", item)
        taxPercentage = Math.round2(100.0 * tax.numericalValue() - 100.0, 0.000001)
        count = Math.decimalCount(taxPercentage)
        if amount.numericalValue() >= Math.pow(10, count)
          if adaptativeMethod != "tax_quantity"
            adaptativeMethod = "tax_quantity"
            E.trade.methods.computeTaxQuantity(item, changedComponent)
        else
          if adaptativeMethod != "quantity_tax"
            adaptativeMethod = "quantity_tax"
            E.trade.methods.computeQuantityTax(item, changedComponent)
        item.prop("adaptativeMethod", adaptativeMethod)

    ops:
      mmma: (item) ->
        E.trade.divide(item, "pretax_amount", "amount", "tax")
      mmmb: (item) ->
        E.trade.divide(item, "unit_amount", "amount", "quantity")
      mmmc: (item) ->
        E.trade.divide(item, "unit_pretax_amount", "pretax_amount", "quantity")
      mmmd: (item) ->
        E.trade.multiply(item, "amount", "pretax_amount", "tax")
      mmme: (item) ->
        E.trade.divide(item, "unit_pretax_amount", "unit_amount", "tax")
      mmmf: (item) ->
        E.trade.multiply(item, "unit_amount", "unit_pretax_amount", "tax")
      mmmg: (item) ->
        E.trade.multiply(item, "pretax_amount", "unit_pretax_amount", "quantity")
      mmmh: (item) ->
        E.trade.multiply(item, "amount", "unit_amount", "quantity")

    find: (name, item) ->
      item.find("*[data-trade-component='#{name}']")

    divide: (item, recipient, numerator, denominator) ->
      r = E.trade.find(recipient, item)
      n = E.trade.find(numerator, item)
      d = E.trade.find(denominator, item)
      value = n.numericalValue() / d.numericalValue()
      r.val(value.toFixed(2))

    multiply: (item, recipient, operand, coefficient) ->
      r = E.trade.find(recipient, item)
      o = E.trade.find(operand, item)
      c = E.trade.find(coefficient, item)
      value = o.numericalValue() * c.numericalValue()
      r.val(value.toFixed(2))

    setReferenceValue: (item, referenceValue, componentType = null) ->
      unless componentType?
        componentType = referenceValue.val()
      if componentType == "unit_pretax_amount" or componentType == "unit_amount" or componentType == "pretax_amount" or componentType == "amount"
        # Register reference value
        referenceValue.val(componentType)
        # Set class for reference field
        item.find("*[data-trade-component].#{E.trade.referenceClass}").removeClass(E.trade.referenceClass)
        item.find("*[data-trade-component='#{componentType}']").addClass(E.trade.referenceClass)

    compute: (item, component = null) ->
      form = item.closest("form")
      changedComponent = null
      referenceValue = item.find("*[data-trade-component='reference_value']")

      if component
        componentType = component.data("trade-component")
        E.trade.setReferenceValue(item, referenceValue, componentType)

      # Computes values
      method = form.find("*[data-trade-method]:checked").val()

      # Get reference value
      changedComponent = referenceValue.val()

      # Apply method
      if method == "quantity_tax"
        E.trade.methods.computeQuantityTax(item, changedComponent)
      else if method == "tax_quantity"
        E.trade.methods.computeTaxQuantity(item, changedComponent)
      else if method == "adaptative"
        E.trade.methods.computeAdaptive(item, changedComponent)
      else if method == "manual"
        E.trade.methods.computeManual(item, changedComponent)
      else
        console.error "Cannot compute anything with #{method} method"

  # Computes changes on items
  $(document).behave "load", "form *[data-trade-item] *[data-trade-component='reference_value']", ->
    E.trade.setReferenceValue $(this).closest("*[data-trade-item]"), $(this)

  # Computes changes on items
  $(document).on "keyup change", "form *[data-trade-item] *[data-trade-component]", ->
    E.trade.compute $(this).closest("*[data-trade-item]"), $(this)

  # Computes changes on items
  $(document).on "change", "form *[data-trade-method]", ->
    $(this).closest("form").find("*[data-trade-item]").each ->
      E.trade.compute $(this)

  return
) ekylibre, jQuery
