((E, $) ->
  'use strict'

  $(document).behave "load click", "form label input[name='parcel[delivery_mode]']", ->
    input = $(this)
    if input.is(':checked')
      form = input.closest('form')
      form.find("input[name='parcel[delivery_mode]']").each ->
        $("#delivery-mode-#{$(this).val()}").hide()
      $("#delivery-mode-#{input.val()}").show()

  $(document).behave "load click", "form label input[name='delivery[mode]']", ->
    input = $(this)
    if input.is(':checked')
      form = input.closest('form')
      form.find("input[name='delivery[mode]']").each ->
        $("##{$(this).val()}").hide()
      $("##{input.val()}").show()


  # Manage fields filling in sales/purchases
  $(document).on "selector:change", "*[data-product-of-delivery-item]", ->
    element = $(this)
    options = element.data("product-of-delivery-item")
    product_id = element.selector('value')
    reg = new RegExp("\\bRECORD_ID\\b", "g")
    if product_id?
      item = element.closest(".delivery-item")
      $.ajax
        url: options.url.replace(reg, product_id)
        dataType: "json"
        success: (data, status, request) ->
          unit = item.find(".item-population-unit-name")
          if data.unit_name
            unit.html(data.unit_name)
          else
            unit.html('#')
          if data.variant
            item.find(".item-variant-name").html(data.variant.name)
          pop = item.find(".item-population")
          total = item.find(".item-population-total")
          if data.population
            total.html(data.population)
            pop.attr('placeholder', data.population)
          else
            total.html('&ndash;')
            pop.attr('placeholder', '0')
          pop.attr('min', 0)
          pop.attr('max', data.population)
          if data.population_counting is 'unitary'
            pop.attr('disabled', 'disabled')
          else
            pop.removeAttr('disabled')

          if data.population_counting is 'integer'
            pop.attr('step', 1)
          else if data.population_counting is 'decimal'
            pop.removeAttr('step')

          item.find('*[data-when-item]').each ->
            if typeof data[$(this).data('when-item')] != "undefined"
              if typeof $(this).data("when-set-value") != "undefined"
                if $(this).data("when-set-value") == "RECORD_VALUE"
                  newVal = data[$(this).data("when-item")]
                  newVal = newVal.toLowerCase() if typeof newVal == "string"

                  if $(this).is ":ui-selector"
                    $(this).selector("value", newVal)
                  else if $(this)._flatpickr?
                    $(this).setDate(newVal)
                  else if $(this).is "input"
                    $(this).val(newVal)
                  else
                    $(this).html(newVal)

                  $(this).trigger 'change'

                  if typeof newVal == "string"
                    element = $(@)
                    element.is(":ui-mapeditor")
                    try
                      value = $.parseJSON(newVal)

                      if (value.geometries? and value.geometries.length > 0) || (value.coordinates? and value.coordinates.length > 0)
                        element.mapeditor "show", value
                        element.mapeditor "edit", value
                        try
                          element.mapeditor "view", "edit"

                    catch
                      newVal = newVal.toLowerCase()

                  $(this).val(newVal)
                else
                  $(this).val($(this).data("when-set-value"))

              if typeof $(this).data("when-prop-value") != "undefined"
                $(this).prop($(this).data("when-prop-value"), true)

              if typeof $(this).data("when-display-value") != "undefined"
                if $(this).data("when-display-value") == true
                  $(this).show()
                else
                  $(this).hide()

            else
              if typeof $(this).data("when-prop-value") != "undefined"
                $(this).prop($(this).data("when-prop-value"), false)

              if typeof $(this).data("when-display-value") != "undefined"
                if $(this).data("when-display-value") == true
                  $(this).hide()
                else
                  $(this).show()

          # shape = item.find(options.population_field or ".item-shape")
          # if data.shape
          #   shape.show()
          # else
          #   shape.hide()

        # Overrides flatpickr input
        flatpickrInput = $('input.datetime.required.flatpickr-input.form-control.input')
        flatpickrInput.attr("data-when-item", "achieved_at") && flatpickrInput.attr("data-when-set-value", "RECORD_VALUE")

        error: (request, status, error) ->
          console.log("Error while retrieving price and tax fields content: #{error}")
    else
      console.warn "Cannot get product ID"


  # Computes changes on items
  $(document).on "click", ".item-parted", (event) ->
    parted = $(this)
    item = parted.closest('.delivery-item')
    quantifier = item.find('.item-quantifier')
    if quantifier
      if parted.is(':checked')
        quantifier.removeClass('hidden')
      else
        quantifier.addClass('hidden')


  return
) ekylibre, jQuery
