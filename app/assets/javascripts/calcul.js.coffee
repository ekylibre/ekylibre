(($, C) ->

  # Format number to be read properly
  C.formatNumber = (value, decimal, separator, thousand) ->
    deci = Math.round(10 ** decimal * (Math.abs(value) - Math.floor(Math.abs(value))))
    val = Math.floor(Math.abs(value))
    if decimal == 0 or deci == 10 ** decimal
      val = Math.floor(Math.abs(value))
      deci = 0
    valFormat = val + ''
    nb = valFormat.length
    i = 1
    while i < 4
      if val >= 10 ** (3 * i)
        valFormat = valFormat.substring(0, nb - 3 * i) + thousand + valFormat.substring(nb - 3 * i)
      i++
    if decimal > 0
      decim = ''
      j = 0
      while j < decimal - deci.toString().length
        decim += '0'
        j++
      deci = decim + deci.toString()
      valFormat = valFormat + separator + deci
    if parseFloat(value) < 0
      valFormat = '-' + valFormat
    valFormat

  # Format number simply
  C.formatNumber2 = (value, precision, separator, thousand) ->
    if isNaN(value)
      return 'NaN'
    coeff = 1
    if value < 0
      coeff = -1
    splitted = Math.abs(value).toString().split(/\./g)
    # alert(splitted.length);
    integers = splitted[0].replace(/^0+[1-9]+/g, '')
    decimals = (splitted[1] or '').replace(/0+$/g, '')
    while decimals.length < precision
      decimals = decimals + '0'
    formatted = integers
    if !/^\s*$/.test(decimals)
      formatted = formatted + separator + decimals
    if coeff < 0
      formatted = "-" + formatted
    formatted

  # Display a number with money presentation
  C.toCurrency = (value) ->
    C.formatNumber2 value, 2, '.', ''

  # Auto-calculation
  C.autoCalculate = ->
    $("*[data-use][data-auto-calculate]").each ()->
      C.calculate.call($(this), false)
    return

  # Test change on value and trigger change event if value is really different
  C.changeNumericalValue = (element, result, force = false) ->
    if element.numericalValue() != result or force
      element.numericalValue result
      element.trigger "change"
    return element

  # Adds a plugin to jQuery to work with numerical values.
  $.fn.numericalValue = (newValue) ->
    element = $(@get(0))
    if isNaN(newValue) or newValue is undefined or newValue is null
      # Get
      value = element.extractNumericalValue()
      coeff = 1
      coeff = -1 if /^\s*\-/.test(value)
      commas = value.split(/\,/g)
      points = value.split(/\./g)
      if commas.length is 2 and points.length isnt 2 # Metric notation
        value = value.replace(/\./g, "").replace(/\,/g, ".")
      else if commas.length is 2 and points.length is 2 and commas[0].length > points[0].length
        value = value.replace(/\./g, "").replace(/\,/g, ".")
      else
        value = value.replace(/\,/g, "")
      value = parseFloat(value.replace(/[^0-9\.]*/g, ""))
      return 0 if isNaN(value)
      value *= coeff
      return value
    else
      # Set
      if element.is("input")
        element.val C.toCurrency(newValue)
      else
        element.html C.toCurrency(newValue)
      element


  # Adds a plugin to jQuery to work with numerical values.
  $.fn.extractNumericalValue = ->
    element = $(this)
    value = undefined
    if element.is("select[data-value]")
      value = element.find("option:selected").attr("data-#{element.data('value')}")
    else if element.is("select")
      value = element.find("option:selected").attr("value")
    else if element.is("input")
      value = element.val()
    else
      value = element.html()
    value = "0.0"  if value is undefined
    value

  $.fn.isCalculationResult = ->
    element = $(this)
    neverUsed = true
    $("*[data-calculate][data-use]").each ->
      $($(this).data("use")).each ->
        neverUsed = false if this is element
    neverUsed

  # Calculate result base on markup
  C.calculate = (force = false)->
    element = $(this)
    result = null
    use = element.data("use")
    if use?
      closest = element.data("use-closest")
      if closest is null or closest is undefined
        use = $(use)
      else
        use = element.closest(closest).find(use)
      calculation = element.data("calculate")
      if calculation is "multiplication" or calculation is "mul"
        result = 1
        use.each ->
          result = result * C.calculate.call(this)
      else # Sum by default
        result = 0
        use.each ->
          result = result + C.calculate.call(this)
      if element.data("divide-by")
        result = result / C.calculate.call($(element.data("divide-by")))

      round = parseInt(element.data("calculate-round"))
      unless isNaN(round)
        result = parseFloat(result.toFixed(round))
    else
      return element.numericalValue()

    C.changeNumericalValue(element, result, force)

    return result

  # Compute the sum of the elements
  $.fn.sum = ->
    result = 0
    @each ->
      result = result + $(this).numericalValue()
    result

  computeValidity = (element, selector, difference = false) ->
    value = null
    equality = true
    $(selector).each ->
      value ?= $(this).numericalValue()
      equality = false if value != $(this).numericalValue()
    equality = equality isnt difference
    if element.hasClass("valid") and !equality
      element.removeClass "valid"
      element.addClass "invalid"
      element.trigger "change"
    else if element.hasClass("invalid") and equality
      element.removeClass "invalid"
      element.addClass "valid"
      element.trigger "change"
    else if equality
      element.addClass("valid")
    else
      element.addClass("invalid")

  # Use element to compute a calculation
  $(document).behave "load", "*[data-use]", ->
    element = $(this)
    if element.isCalculationResult()
      element.attr "data-auto-calculate", "true"
    else
      element.removeAttr "data-auto-calculate"
    return

  $(document).behave "load", "*[data-balance]", ->
    element = $(this)
    operands = $(this).data("balance").split('\\-').join('@DASH@').split(/\s\-\s/g).slice(0, 2).map (elem) ->
      elem.split('@DASH@').join('-')
    round = parseInt(element.data("calculate-round"))
    $(document).on "change", operands.join(", "), ->
      plus = $(operands[0]).sum()
      minus = $(operands[1]).sum()
      result = 0
      if plus > minus
        result = plus - minus
      unless isNaN(round)
        result = parseFloat(result.toFixed(round))
      element.numericalValue(result)
    return

  $(document).behave "load", "*[data-difference]", ->
    element = $(this)
    round = parseInt(element.data("calculate-round"))
    operands = $(this).data("difference").split('\\-').join('@DASH@').split(/\s+\-\s+/g).slice(0, 2).map (elem) ->
      elem.split('@DASH@').join('-')
    $(document).on "change", operands.join(", "), ->
      result = $(operands[0]).sum() - $(operands[1]).sum()
      unless isNaN(round)
        result = parseFloat(result.toFixed(round))
      C.changeNumericalValue(element, result)
    return

  $(document).behave "load keyup change", "*[data-less-than-or-equal-to]", ->
    element = $(this)
    maximum = parseFloat(element.data("less-than-or-equal-to"))
    if element.numericalValue() > maximum
      element.removeClass "valid"
      element.addClass "invalid"
    else
      element.removeClass "invalid"
      element.addClass "valid"
    return

  $(document).behave "load keyup change", "*[data-check-positive]", ->
    element = $(this)
    value = element.find(element.data("check-positive")).numericalValue()
    if value < 0
      element.removeClass "valid"
      element.addClass "invalid"
    else if value > 0
      element.removeClass "invalid"
      element.addClass "valid"
    else
      element.removeClass "invalid"
      element.removeClass "valid"
    return

  $(document).behave "load", "*[data-valid-if-equality-between]", ->
    element = $(this)
    selector = element.data("valid-if-equality-between")
    $(document).behave "load keyup change", selector, ->
      computeValidity(element, selector)
    $(document).on "visibility:change", (event, hiddenOrShown) ->
      isParent = $(selector).toArray().some (triggerElement) ->
        $.contains hiddenOrShown, triggerElement
      computeValidity(element, selector) if isParent
      return
    return

  $(document).behave "load", "*[data-valid-if-difference-between]", ->
    element = $(this)
    selector = element.data("valid-if-difference-between")
    $(document).behave "load keyup change", selector, ->
      computeValidity(element, selector, true)
    $(document).on "visibility:change", (event, hiddenOrShown) ->
      isParent = $(selector).toArray().some (triggerElement) ->
        $.contains hiddenOrShown, triggerElement
      computeValidity(element, selector, true) if isParent
      return
    return

  $(document).on "change", "*[data-valid-if-equality-between]", ->
    element = $(this)
    if element.hasClass("valid") && element.data("submit-if-valid") == true
      form = element.closest("form")
      form.submit() if form
    return


  C.autoCalculate()

  window.setInterval C.autoCalculate, 300


  return
) jQuery, calcul
