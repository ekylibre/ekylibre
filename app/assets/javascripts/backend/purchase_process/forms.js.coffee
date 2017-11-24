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
      quantity_value = parseFloat(conditionning.val()) * parseFloat(conditionning_quantity.val())
      quantity.val(quantity_value)
      E.trade.updateUnitPretaxAmount(item)
      E.toggleValidateButton(item)

  $(document).on "keyup change", "*[data-trade-component]", (event) ->
    component = $(this)
    item = component.closest(".storing-fields")
    component_name = component.data('trade-component')
    if component_name == 'conditionning' || component_name == 'conditionning_quantity' && item.length > 0
      conditionning = item.find('.conditionning')
      conditionning_quantity = item.find('.conditionning-quantity')
      quantity = item.find('.storing-quantity')
      quantity_value = parseFloat(conditionning.val()) * parseFloat(conditionning_quantity.val())
      quantity.val(quantity_value)
    if component_name == 'conditionning'
      $('.conditionning').val(item.find('.conditionning').val())

  $(document).ready ->
    $('table.list').on 'cocoon:after-insert', ->
      $('*[data-iceberg]').on "iceberg:inserted", ->
        $('.conditionning').val($('.conditionning').val())

) ekylibre, jQuery
