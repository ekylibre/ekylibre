#= require selector
#= require calcul

((E, C, $) ->
  'use strict'

  # Updates indicator/units list
  # TODO Optimize this binding only valid selectors
  $(document).on 'selector:change', "input[data-selector]", ->
    selector = $(this)
    root = selector.data("use-closest")
    root = "form" unless root?
    form = selector.closest(root)
    form.find("*[data-variant-quantifier='#{selector.attr('id')}']").each ->
      select = $(this)
      options = {}
      options.population = true if select.data("quantifiers-population")
      options.working_duration = true if select.data("quantifiers-working-duration")
      $.ajax
        url: "/backend/product_nature_variants/#{selector.selector('value')}/quantifiers.json"
        data: options
        success: (data, status, request) ->
          select.html("")
          $.each data, (index, item) ->
            option = $("<option></option>")
              .html(item.label)
              .attr("value", "#{item.indicator}-#{item.unit}")
              .attr("data-indicator", item.indicator)
              .attr("data-unit", item.unit)
              .attr("data-unit-symbol", item.unit_symbol)
              .appendTo(select)
          select.trigger("change")
        error: () ->
          console.error "Cannot retrieve quantifiers of variant ID=#{selector.val()}"
    true

  # Set values in hidden fields indicator/unit
  $(document).on 'change keyup', "select[data-variant-quantifier]", ->
    select = $(this)
    option = select.find("option:selected")
    indicator = option.data("indicator")
    unit = option.data("unit")
    changed = false

    # Sets values in hidden fields
    field = select.siblings(".quantifier-indicator").first()
    changed = true if field.val() != indicator
    field.val(indicator)

    field = select.siblings(".quantifier-unit").first()
    changed = true if field.val() != unit
    field.val(unit)

    # Trigger only after value are set
    if changed
      select.siblings(".quantifier-unit").trigger("unit:change", [indicator, unit, option.data("unit-symbol")])
    true

  # Retrieves quantity with selected quantifier
  # TODO Optimizes query count
  $(document).on "unit:change", "#production_support_variant_unit", (event, indicator, unit, unitSymbol)->
    form = $(this).closest("form")
    # Set unit symbol
    form.find(".working-unit").html(unitSymbol)

    total = form.find("#supports-quantity").numericalValue()

    form.find("#supports .support").each ->
      support = $(this)
      support.addClass("waiting")
      # FIXME Quite bad, do not use non-specific/generic attributes
      id = support.find("*[data-parameter-name='storage_id']").val()
      $.ajax
        url: "/backend/products/#{id}/take.json"
        data:
          indicator: indicator
          unit: unit
        success: (data, status, request) ->
          support.find(".support-quantity").html(data.value)
          support.find(".support-unit").html(unitSymbol)
          support.removeClass("waiting")
          if form.find("#supports .support.waiting").length == 0
            newTotal = C.calculate.call(form.find("#supports-quantity"))
            E.changeQuantities(form, total/newTotal)
    true

  # Retrieves quantity with selected quantifier for a given support
  $(document).on "selector:change", "#supports .support input[data-parameter-name='storage_id']", (event)->
    support = $(this).closest(".support")
    form = $(this).closest("form")
    option = form.find("select[data-variant-quantifier] option:selected")
    indicator = option.data("indicator")
    unit = option.data("unit")
    unitSymbol = option.data("unit-symbol")
    # Set unit symbol
    form.find(".total .unit").html(unitSymbol)
    # FIXME Quite bad, do not use non-specific/generic attributes
    id = support.find("*[data-parameter-name='storage_id']").val()
    $.ajax
      url: "/backend/products/#{id}/take.json"
      data:
        indicator: indicator
        unit: unit
      success: (data, status, request) ->
        support.find(".support-quantity").html(data.value)
        support.find(".support-unit").html(unitSymbol)
    true

  # Change budget coeff on computation method change
  $(document).on "change keyup", ".budget .computation-method", (event)->
    select = $(this)
    budget = select.closest(".budget")
    form = budget.closest("form")
    coeff = E.coefficientValue(form, select.val())
    # Set coeff
    budget.find(".budget-coeff").numericalValue(coeff)
    # Find total
    total_quantity = budget.find(".budget-amount").numericalValue() / budget.find(".budget-unit-amount").numericalValue()
    # Adjust quantity to maintain global total
    quantity = budget.find(".budget-quantity")
    if total_quantity > 0
      round = 3
      round = quantity.data("calculate-round") if quantity.data("calculate-round")?
      quantity.numericalValue((total_quantity / coeff).toFixed(round))
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
  $(document).on "cocoon:after-remove", "#supports", (event)->
    console.log "Delete support"
    form = $(this).closest("form")
    form.find(".computation-method").each ->
      select = $(this)
      coeff = E.coefficientValue(form, select.val())
      C.changeNumericalValue(select.closest(".budget").find(".budget-coeff"), coeff)
    true

  # Refresh totals after insert
  $(document).on "cocoon:after-insert", ".budgets", (event)->
    $(this).find(".budget select.computation-method").each ->
      select = $(this)
      select.trigger("change")
    true

  # Show working unit dependent stuff
  $(document).behave "load change", "#supports-quantity", (event)->
    quantity = $(this).numericalValue()
    if quantity > 0
      $(".with-some-supports").show()
    else
      $(".with-some-supports").hide()
    true

  E.coefficientValue = (form, name) ->
    coeff = 1
    if name is "per_production_support"
      coeff = form.find("#supports .support:visible").length
    else if name is "per_working_unit"
      coeff = form.find("#supports-quantity").numericalValue()
    return coeff

  E.changeQuantities = (form, coeff) ->
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
    support.attr("data-selector", url)
    support.data("selector", url)
    true

  # Show working unit dependent stuff
  $(document).on "selector:change", "#supports .support .production_supports_storage input[data-selector]", (event)->
    E.updateAllProductUnrollURL $(this).closest('form')

  # Show working unit dependent stuff
  $(document).on "cocoon:after-insert", "#supports", (event)->
    E.updateAllProductUnrollURL $(this).closest('form')

  # Show working unit dependent stuff
  $(document).behave "selector:set", "#production_support_variant_id", (event)->
    variant = $(this)
    id = variant.selector('value')
    form = variant.closest('form')
    if /^\d+$/.test(id)
      form.find(".with-supports").show()
      E.updateAllProductUnrollURL(form)
    else
      form.find(".with-supports").hide()
    true

) ekylibre, calcul, jQuery
