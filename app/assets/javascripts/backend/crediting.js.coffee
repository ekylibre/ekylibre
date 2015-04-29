# allows price and tax auto filling in sales view

((E, $) ->
  'use strict'

  E.crediting =
    # CSS class for reference fields
    referenceClass: "special"

    methods:
      computeManual: (item, changedComponent) ->
        console.log "Compute Manual method from #{changedComponent}"
        # Do nothing for now

      computeQuantityTax: (item, changedComponent) ->
        console.log "Compute Quantity-Tax method from #{changedComponent}"
        if changedComponent == "amount"
          E.crediting.ops.mmmz(item)
          E.crediting.ops.mmmy(item)
        else if changedComponent == "pretax_amount"
          E.crediting.ops.mmmx(item)
          E.crediting.ops.mmmw(item)
        else if changedComponent == "quantity"
          E.crediting.ops.mmmw(item)
          E.crediting.ops.mmmy(item)
        else
          console.error "Cannot compute anything for #{changedComponent}"

      computeTaxQuantity: (item, changedComponent) ->
        console.log "Compute Tax-Quantity method from #{changedComponent}"
        if changedComponent == "amount"
          E.crediting.ops.mmmv(item)
          E.crediting.ops.mmmx(item)
        else if changedComponent == "pretax_amount"
          E.crediting.ops.mmmu(item)
          E.crediting.ops.mmmx(item)
        else if changedComponent == "quantity"
          E.crediting.ops.mmmy(item)
          E.crediting.ops.mmmu(item)
        else
          console.error "Cannot compute anything for #{changedComponent}"

      computeAdaptive: (item, changedComponent) ->
        adaptativeMethod = item.prop("adaptativeMethod")
        if adaptativeMethod == "tax_quantity"
          E.crediting.methods.computeTaxQuantity(item, changedComponent)
        else if adaptativeMethod == "quantity_tax"
          E.crediting.methods.computeQuantityTax(item, changedComponent)
        # Evaluate if re-computation is needed
        amount = E.crediting.find("unit_pretax_amount", item)
        tax = E.crediting.find("tax", item)
        taxPercentage = Math.round2(100.0 * tax.numericalValue() - 100.0, 0.000001)
        count = Math.decimalCount(taxPercentage)
        if amount.numericalValue() >= Math.pow(10, count)
          if adaptativeMethod != "tax_quantity"
            adaptativeMethod = "tax_quantity"
            E.crediting.methods.computeTaxQuantity(item, changedComponent)
        else
          if adaptativeMethod != "quantity_tax"
            adaptativeMethod = "quantity_tax"
            E.crediting.methods.computeQuantityTax(item, changedComponent)
        item.prop("adaptativeMethod", adaptativeMethod)

    ops:
      mmmz: (item) ->
        E.crediting.divide(item, "quantity", "amount", "unit_amount")
      mmmy: (item) ->
        E.crediting.multiply(item, "pretax_amount", "unit_pretax_amount", "quantity")
      mmmx: (item) ->
        E.crediting.divide(item, "quantity", "pretax_amount", "unit_pretax_amount")
      mmmw: (item) ->
        E.crediting.multiply(item, "amount", "unit_amount", "quantity")
      mmmv: (item) ->
        E.crediting.divide(item, "pretax_amount", "amount", "tax")
      mmmu: (item) ->
        E.crediting.multiply(item, "amount", "pretax_amount", "tax")

    find: (name, item) ->
      item.find("*[data-crediting-component='#{name}']")

    divide: (item, recipient, numerator, denominator) ->
      r = E.crediting.find(recipient, item)
      n = E.crediting.find(numerator, item)
      d = E.crediting.find(denominator, item)
      value = n.numericalValue() / d.numericalValue()
      r.val(value.toFixed(2))

    multiply: (item, recipient, operand, coefficient) ->
      r = E.crediting.find(recipient, item)
      o = E.crediting.find(operand, item)
      c = E.crediting.find(coefficient, item)
      value = o.numericalValue() * c.numericalValue()
      r.val(value.toFixed(2))

    setReferenceValue: (item, referenceValue, componentType = null) ->
      unless componentType?
        componentType = referenceValue.val()
      if componentType == "quantity" or componentType == "pretax_amount" or componentType == "amount"
        # Register reference value
        referenceValue.val(componentType)
        # Set class for reference field
        item.find("*[data-crediting-component].#{E.crediting.referenceClass}").removeClass(E.crediting.referenceClass)
        item.find("*[data-crediting-component='#{componentType}']").addClass(E.crediting.referenceClass)

    compute: (item, component = null) ->
      form = item.closest("form")
      changedComponent = null
      referenceValue = item.find("*[data-crediting-component='reference_value']")

      if component
        componentType = component.data("crediting-component")
        E.crediting.setReferenceValue(item, referenceValue, componentType)

      # Computes values
      creditingMethod = form.find("*[data-crediting-method]")
      if creditingMethod.is("input[type='radio']")
        method = form.find("*[data-crediting-method]:checked").val()
      else
        method = creditingMethod.val()

      # Get reference value
      changedComponent = referenceValue.val()

      # Apply method
      if method == "quantity_tax"
        E.crediting.methods.computeQuantityTax(item, changedComponent)
      else if method == "tax_quantity"
        E.crediting.methods.computeTaxQuantity(item, changedComponent)
      else if method == "adaptative"
        E.crediting.methods.computeAdaptive(item, changedComponent)
      else if method == "manual"
        E.crediting.methods.computeManual(item, changedComponent)
      else
        console.error "Cannot compute anything with #{method} method"

  # Computes changes on items
  $(document).behave "load", "form *[data-crediting-item] *[data-crediting-component='reference_value']", ->
    E.crediting.setReferenceValue $(this).closest("*[data-crediting-item]"), $(this)

  # Computes changes on items
  $(document).on "keyup change", "form *[data-crediting-item] *[data-crediting-component]", ->
    E.crediting.compute $(this).closest("*[data-crediting-item]"), $(this)

  # Computes changes on items
  $(document).on "change", "form *[data-crediting-method]", ->
    $(this).closest("form").find("*[data-crediting-item]").each ->
      E.crediting.compute $(this)

  # Computes changes on items
  $(document).on "keyup keydown", "form input[data-force-sign='-']", ->
    $(this).each () ->
      input = $(this)
      unless input.val().match(/^\-/)
        input.val "-#{input.val()}"

  return
) ekylibre, jQuery
