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
    prevRow.next('.frequencies').remove()

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
      $('.required-support').hide()
    true

  # Referesh totals after delete support
  $(document).on "cocoon:after-insert", ".budget-items", (event)->
    $(event.currentTarget).find('.budget-amount').each ->
      $(this).html(C.toBudgetCurrency($(this).numericalValue()))
    if $('#supports-quantity').numericalValue() <= 0
      $('.required-support').hide()

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

  E.onDomReady ->
    $('.budget-amount').each () ->
      $(this).html(C.toBudgetCurrency($(this).numericalValue()))
    $('.activity_budget_revenues_main_output .checkbox input').each () ->
      $(this).trigger('main_output:set')
    $('.activity_budget_revenues_use_transfer_price .checkbox input').each () ->
      E.changeTransferPriceDisplay($(this), $(this).is(':checked'))
    $('.budget-locked').each () ->
      if $('.budget-locked').val() == 'true'
        $(this).closest('.budget').addClass('budget-item-locked')
        $(this).closest('.budget').next('.frequencies').addClass('budget-item-locked')

  $(document).behave "change", ".activity_budget_revenues_main_output .checkbox input", (event)->
    $(this).trigger('main_output:set')

  $(document).behave "change", ".budget-total .amount", (event)->
    $('.activity_budget_revenues_use_transfer_price .checkbox input').each () ->
      E.updateTransferPrice($(this))

  $(document).behave "change", ".activity_budget_revenues_use_transfer_price .checkbox input", (event)->
    if $(this).is(':checked')
      E.changeTransferPriceDisplay($(this), true)
      $(this).closest('.frequencies').next('.transfered-activity').show()
    else
      E.changeTransferPriceDisplay($(this), false)
      $(this).closest('.frequencies').next('.transfered-activity').hide()

  $(document).behave "main_output:set", ".activity_budget_revenues_main_output .checkbox input", (event) ->
    if $(this).is(':checked')
      if $(".activity_budget_revenues_main_output .checkbox input:checked").length > 1
        $('.activity_budget_revenues_main_output .checkbox input').prop('checked', false).trigger('change')
        $(this).prop('checked', true)
      $(this).closest('.frequencies').find('.transfer-price').show()
      $(this).closest('.frequencies').find('.use-transfer-price').show()
      $(this).closest('.frequencies').find('.activity_budget_revenues_use_transfer_price .checkbox input').trigger('change')
    else
      $(this).closest('.frequencies').find('.activity_budget_revenues_use_transfer_price .checkbox input').prop('checked', false).trigger('change')
      $(this).closest('.frequencies').find('.use-transfer-price').hide()
      $(this).closest('.frequencies').find('.transfer-price').hide()

  E.updateTransferPrice = (element) ->
    budget = element.closest('.frequencies').prev('.budget')
    wu = if $('th.with-some-supports').css('display') != 'none' then '-per-working-unit' else ''
    non_taken_revenue = budget.find('.revenue-amount'+wu).numericalValue()
    revenues = $(".revenue-amount"+wu)
    expenses = $('#expenses-amount'+wu).numericalValue()
    mapped_revenues = $.map revenues, (val, i) ->
      $(val).numericalValue()
    revenues_sum = -(non_taken_revenue);
    $.each mapped_revenues, ->
      revenues_sum += this
    quantity = parseFloat(budget.find('.budget-quantity').val())
    transfer_price = ((expenses - revenues_sum)/quantity).toFixed(2)
    transfer_price = if $.isNumeric(transfer_price) then transfer_price else 0.00
    element.closest('.frequencies').find('.transfer-price-box').html(transfer_price)
    element.closest('.frequencies').find('.v-transfer-price').attr('value', transfer_price)
    if element.is(':checked')
      budget.find('.activity_budget_revenues_unit_amount span input').attr('value',transfer_price).prop('value',transfer_price)
    return transfer_price

  E.changeTransferPriceDisplay = (element, state) ->
    transfer_price = E.updateTransferPrice(element)
    if state
      element.closest('.frequencies').prev('.budget').find('.activity_budget_revenues_unit_amount span input').attr('value', transfer_price)
      element.closest('.frequencies').prev('.budget').find('.activity_budget_revenues_unit_amount span input').prop("disabled", true)
    else
      element.closest('.frequencies').prev('.budget').find('.activity_budget_revenues_unit_amount span input').prop("disabled",false)

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
