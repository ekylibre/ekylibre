((E, $) ->
  productsInfos =
    displayProductsInfos: () ->
      that = this
      $('.nested-plant_medicine').each -> that._removeProductInfos($(this))
      values = that._retrieveValues()

      $.getJSON "/backend/registered_phytosanitary_products/get_products_infos", values, (data) =>
        for id, infos of data
          $productField = $(".selector-value[value='#{id}']").closest('.nested-plant_medicine')
          @._displayAllowedMentions($productField, infos.allowed_mentions)
          @._displayBadge($productField, infos.state)
          @._displayMessages($productField, infos.messages)

    _displayAllowedMentions: ($productField, allowedMentions) ->
      $productField.find('span.allowed-mentions').insertAfter($productField.find('.intervention_inputs_product .selector'))
      for mention in allowedMentions
        $productField.find("##{mention}").show()

    _displayBadge: ($productField, state) ->
      $productField.find('#intervention-products-badges').addClass("state-badge-set--#{state}")

    _displayMessages: ($productField, messages) ->
      $productField.find('#product-authorization-message').html(messages.join('<br>'))

    _removeProductInfos: ($productField) ->
#      $productField.find('.lights').removeClass("lights-go lights-caution lights-stop")
#      $productField.find('.lights-message').text("")
      $productField.find('.allowed-mentions img').each -> $(this).hide()
      $productField.find('#intervention-products-badges').removeClass("state-badge-set--allowed state-badge-set--forbidden")

    _retrieveValues: () ->
      targetsIds = $('.nested-cultivation').map ->
        $(this).find("[data-selector-id='intervention_target_product_id']").next('.selector-value').val()
      productsIds = $(".nested-plant_medicine").map ->
        $(this).find("[data-selector-id='intervention_input_product_id']").next('.selector-value').val()
      usagesIds = $(".nested-plant_medicine").map ->
        $(this).find("[data-selector-id='intervention_input_usage_id']").next('.selector-value').val()

      { products_ids: _.compact(productsIds.toArray()), targets_ids: _.compact(targetsIds.toArray()), usages_ids: _.compact(usagesIds.toArray()) }


  # Update products infos on target remove
  $(document).on 'cocoon:after-remove', '.nested-targets', ->
    $("[data-selector-id='intervention_input_product_id']").trigger('selector:change')

  $(document).on 'cocoon:after-remove', '.nested-inputs', ->
    productsInfos.displayProductsInfos()

  # Re-trigger all filters on target change
  $(document).on 'selector:change', "[data-selector-id='intervention_target_product_id']", ->
    $("[data-selector-id='intervention_input_product_id']").trigger('selector:change')

  $(document).on 'selector:change', "[data-selector-id='intervention_input_usage_id']", ->
    productsInfos.displayProductsInfos()

  # Refresh usages, allowed mentions and badges on product update
  $(document).on 'selector:change', "input[data-selector-id='intervention_input_product_id']", ->
    $usageInput = $(this).closest('.nested-plant_medicine').find("[data-selector-id='intervention_input_usage_id']").first()
    $usageInput.selector('clear')
    $(this).closest('.nested-plant_medicine').find('.usage-infos-container').hide()
    productsInfos.displayProductsInfos()

  # Update usage details on usage change
  $(document).on 'selector:change', "[data-selector-id='intervention_input_usage_id']", ->
    $(this).closest('.nested-plant_medicine').find('#product-authorization-message').text('')
    $(this).closest('.nested-plant_medicine').find('.lights').removeClass("lights-go lights-caution lights-stop")
    $(this).closest('.nested-plant_medicine').find('.lights-message').removeClass('warning').text("")
    $("input[data-intervention-field='quantity-value']").trigger('input')

    usageId = $(this).next('input').val()
    return unless usageId

    targetsData = $('.nested-cultivation').map ->
      {
        id: $(this).find("[data-selector-id='intervention_target_product_id']").next('input').val(),
        shape: $(this).find('[data-map-editor]').val()
      }

    $.getJSON "/backend/registered_phytosanitary_usages/#{usageId}/get_usage_infos", targets_data: targetsData.toArray(), (data) =>
      for key, value of data.usage_infos
        $(this).closest('.nested-fields').find("[data-usage-attribute='#{key}']").text(value || '-')

      $(this).closest('.nested-fields').find('.usage-infos-container').show()

      for key, value of data.usage_application
        addedClass = if key == 'stop' then 'warning' else ''
        $(this).closest('.controls').find('.lights').addClass("lights-#{key}")
        $(this).closest('.controls').find('.lights-message').addClass(addedClass).text("#{value}")

      for key, value of data.allowed_factors
        $(this).closest('.nested-fields').find(".#{key}").val(value)

  # Update allowed doses on quantity change
  $(document).on 'input change', "input[data-intervention-field='quantity-value']", ->
    productId = $(this).closest('.nested-fields').find("[data-selector-id='intervention_input_product_id']").next('input').val()
    quantity = this.value
    dimension = $(this).parent().find('select option:selected').val()
    usageId = $(this).closest('.nested-fields').find("[data-selector-id='intervention_input_usage_id']").next('input').val()
    targetsData = $('.nested-cultivation').map ->
      shape: $(this).find('[data-map-editor]').val()

    if quantity && dimension && usageId && targetsData
      $.getJSON "/backend/registered_phytosanitary_usages/#{usageId}/dose_validations", product_id: productId, quantity: quantity, dimension: dimension, targets_data: targetsData.toArray(), (data) =>

        $(this).closest('.controls').find('.lights').removeClass("lights-go lights-caution lights-stop")
        $(this).closest('.controls').find('.lights-message').removeClass("warning")
        for key, value of data
          addedClass = if key == 'stop' then 'warning' else ''
          $(this).closest('.controls').find('.lights').addClass("lights-#{key}")
          $(this).closest('.controls').find('.lights-message').addClass(addedClass).text("#{value}")

) ekylibre, jQuery
