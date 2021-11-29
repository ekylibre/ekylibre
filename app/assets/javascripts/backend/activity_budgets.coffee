#= require selector
#= require calcul

((E, C, $) ->
  'use strict'
  # Change budget coeff on computation method change
  $(document).on "change keyup", ".budget .computation-method", (event)->
    console.log 'change on computation-method'
    select = $(this)
    budget = select.closest(".budget")
    form = budget.closest("form")
    coeff = E.coefficientValue(form, select.val())
    # Set coeff
    budget.find(".budget-coeff").numericalValue(coeff)
    # Find total
    quantityValue = budget.find(".budget-amount").numericalValue() / budget.find(".budget-unit-amount").numericalValue()
    # Adjust quantity to maintain global total
    quantity = budget.find(".budget-quantity")
    if quantityValue > 0
      round = 3
      round = quantity.data("calculate-round") if quantity.data("calculate-round")?
      quantity.numericalValue((quantityValue / coeff).toFixed(round))
    # Trigger event on quantity only
    quantity.trigger("change")
    true

  # Change budget coeff on supports  quantity change
  $(document).on "change", "#supports-quantity", (event)->
    form = $(this).closest("form")
    form.find(".computation-method").each ->
      select = $(this)
      coeff = E.coefficientValue(form, select.val())
      C.changeNumericalValue(select.closest(".budget").find(".budget-coeff"), coeff)
    true

  # Referesh totals after delete support
  $(document).on "cocoon:after-remove", ".budget", (event)->
    console.log "Delete support"
    form = $(this).closest("form")
    form.find(".computation-method").each ->
      select = $(this)
      coeff = E.coefficientValue(form, select.val())
      C.changeNumericalValue(select.closest(".budget").find(".budget-coeff"), coeff)
    true

    # Referesh totals after delete support
  $(document).on "cocoon:before-remove", ".budget-items", (event, prevRow)->
    prevRow.next('.frequencies').hide()

  # Refresh totals after insert
  $(document).on "cocoon:after-insert", ".budgets", (event)->
    $(this).find(".budget select.computation-method").each ->
      select = $(this)
      select.trigger("change") 
    true 

  # Show working unit dependent stuff
  $(document).behave "load change", "#supports-quantity", (event)->
    quantity = $(this).numericalValue()
    form = $(this).closest("form")
    if quantity > 0
      form.addClass("with-some-supports")
    else
      form.removeClass("with-some-supports")
    true

  E.coefficientValue = (form, name) ->
    coeff = 1
    if name is "per_production_support"
      coeff = form.find("#supports .support.nested-fields").length
    else if name is "per_working_unit"
      coeff = form.find("#supports-quantity").numericalValue()
    return coeff

  # Set the quantity for a support keepping the choosen ratio on quantity
  # in order to maintain global amount
  E.updateSupportQuantity = (support, newRefValue, newRefUnit) ->
    ref   = support.find(".support-current-quantity")
    input = support.find(".support-quantity")
    oldRefValue = ref.numericalValue()
    k = 1
    k = newRefValue / oldRefValue if oldRefValue != 0
    ref.numericalValue(newRefValue)
    round = 3
    round = input.data("calculate-round") if input.data("calculate-round")?
    inputValue = input.numericalValue()
    if inputValue == "" or inputValue == 0
      inputValue = parseFloat(newRefValue)
    else
      inputValue *= k
    input.numericalValue(inputValue.toFixed(round))
    support.find(".support-unit").html(newRefUnit)
    true

  # Changes budget quantities with new coeff
  E.changeBudgetQuantities = (form, coeff) ->
    form.find(".budgets .budget").each ->
      budget = $(this)
      method = budget.find(".budget-computation-method").val()
      quantity = budget.find(".budget-quantity")
      if method == "per_working_unit"
        qty = quantity.numericalValue()
        round = 3
        round = quantity.data("calculate-round") if quantity.data("calculate-round")?
        quantity.numericalValue((qty * coeff).toFixed(round))
        quantity.trigger("change")
    true

  E.updateAllProductUnrollURL = (form) ->
    form.find("#supports .support .production_supports_storage input[data-selector]").each () ->
      E.updateProductUnrollURL $(this)
    true

  E.updateProductUnrollURL = (support) ->
    url = "/backend/products/unroll?scope[supportables]=true"
    form = support.closest("form")
    # Adds variant filter
    variant_id = form.find('#production_support_variant_id').first().selector('value')
    if variant_id?
      url += "&scope[of_variant]=#{variant_id}"
    # Adds exception of the group
    exclusions = []
    form.find("#supports .support .production_supports_storage input[data-selector]").each ->
      if this != support.get(0) and $(this).prop("widgetInitialized")
        value = $(this).selector('value')
        exclusions.push(value) if value?
    for exclusion in exclusions
      url += "&exclude[]=#{exclusion}"
    support.selector()
    support.selector('url', url)
    support.selector('check')
    true


  $(document).on 'change', '.v-budget-frequency', (e) ->
    dic = {per_month: 12, per_day: 365}
    corrected = dic[$(this).find(':selected').val()]
    val = if typeof corrected == 'undefined' then 1 else corrected
    $(this).closest('.noHover').prev().find('.budget-frequency').text(val)

  $(document).on 'keyup', '.v-budget-repetition', (e) ->
    $(this).closest('.noHover').prev().find('.budget-repetition').text($(this).val())

  # Show working unit dependent stuff
  $(document).on "selector:change", "#supports .support .production_supports_storage input[data-selector]", (event)->
    E.updateAllProductUnrollURL $(this).closest('form')

  # Show working unit dependent stuff
  $(document).on "cocoon:after-insert", "#supports", (event)->
    E.updateAllProductUnrollURL $(this).closest('form')

  # Show working unit dependent stuff
  $(document).behave "load selector:set", "#production_support_variant_id", (event)->
    variant = $(this)
    id = variant.selector('value')
    form = variant.closest('form')
    if /^\d+$/.test(id)
      form.addClass("with-supports")
      E.updateAllProductUnrollURL(form)
    else
      form.removeClass("with-supports")
    true

  # Force calculation of final values to ensure that all numbers are clear
  $(document).behave "load", "#revenues-amount, #expenses-amount", ->
    $(this).each () ->
      $(this).trigger('change')

) ekylibre, calcul, jQuery
