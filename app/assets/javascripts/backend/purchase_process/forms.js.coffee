((E, $) ->
  'use strict'

  $(document).on "keyup change", "form *[data-trade-item='purchase'] *[data-trade-component]", (event) ->
    component = $(this)
    item = component.closest("*[data-trade-item]")
    component_name = component.data('trade-component')
    if component_name == 'conditionning' || component_name == 'conditionning_quantity'
      conditionning = E.trade.find(item, 'conditionning')
      conditionning_quantity = E.trade.find(item, 'conditionning_quantity')
      quantity = E.trade.find(item,  'quantity')
      quantity_value = parseFloat(conditionning.val() || 0) * parseFloat(conditionning_quantity.val() || 0)
      quantity.val(quantity_value)
      quantity.trigger('change')
      E.trade.updateUnitPretaxAmount(item)
      E.toggleValidateButton(item)

  $(document).on "keyup change", "*[data-trade-component]", (event) ->
    component = $(this)
    item = component.closest('.storing-fields')
    component_name = component.data('trade-component')

    if component_name == 'conditionning' || component_name == 'conditionning_quantity' && item.length > 0
      conditionning = item.find('.conditionning')
      conditionning_quantity = item.find('.conditionning-quantity')
      quantity = item.find('.storing-quantity')
      quantity_value = parseFloat(conditionning.val() || 0) * parseFloat(conditionning_quantity.val() || 0)
      quantity.val(quantity_value)
      quantity.trigger('change')
      E.toggleValidateButton(item.closest('.incoming-parcel-item'))

    if component_name == 'conditionning'
      val = item.find('.conditionning').val()
      item.closest('#add-storing').find('.conditionning').each ->
        $(this).val(val)
        $(this).closest('.storing-fields').find('.conditionning-quantity').trigger('change')

  fields =
    _stripDecimals: (digitString, wantedDecimals) ->
      if digitString.includes('.')
        amountWithDigits = digitString.split('.')
        amount = amountWithDigits[0]
        digits = amountWithDigits[1]
        if digits.length > wantedDecimals
          digitsKept = digits.substring(0, wantedDecimals)
          amountDisplayed = amount + '.' + digitsKept
          newDigitString = parseFloat(amountDisplayed)

    changeDecimalNumber: (element, wantedDecimals) ->
      newValue = @_stripDecimals(element.value, wantedDecimals)
      element.value = newValue if newValue

  # Prevent having more than 2 decimals on amount fields
  $(document).on "keyup", "[data-trade-component=amount], [data-trade-component=pretax_amount]", ->
    fields.changeDecimalNumber(this, 2)

  # Allow unit pretax amount to have 4 decimals because database stores only 4
  $(document).on "keyup", "[data-trade-component=unit_pretax_amount]", ->
    fields.changeDecimalNumber(this, 4)

  $(document).ready ->
    $('table.list').on 'cocoon:after-insert', ->
      $('*[data-iceberg]').on "iceberg:inserted", (element) ->
        val = $(this).find('.conditionning').val()
        $(this).find('.conditionning').val(val)

) ekylibre, jQuery
