((E, $) ->
  productsInfos =
    display: () ->
      that = this
      $('.nested-plant_medicine').each -> that._clear($(this))
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

    _clear: ($productField) ->
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


  usageMainInfos =
    display: ($input, $productField) ->
      @._clear($productField)
      $productField.find("input[data-intervention-field='quantity-value']").trigger('input')
      usageId = $input.next('.selector-value').val()
      return unless usageId
      values = @._retrieveValues()

      $.getJSON "/backend/registered_phytosanitary_usages/#{usageId}/get_usage_infos", values, (data) =>
        @._displayInfos($productField, data.usage_infos)
        @._displayApplication($input, data.usage_application)
        @._displayAllowedFactors($productField, data.allowed_factors)

    _displayInfos: ($productField, infos) ->
      for key, value of infos
        $productField.find("[data-usage-attribute='#{key}']").text(value || '-')

      $productField.find('.usage-infos-container').show()

    _displayApplication: ($input, application) ->
      for key, value of application
        addedClass = if key == 'stop' then 'warning' else ''
        $input.closest('.controls').find('.lights').addClass("lights-#{key}")
        $input.closest('.controls').find('.lights-message').addClass(addedClass).text("#{value}")

    _displayAllowedFactors: ($productField, allowedFactors) ->
      for key, value of allowedFactors
        $productField.find(".#{key}").val(value)

    _clear: ($productField) ->
      $productField.find('.lights').removeClass('lights-go lights-caution lights-stop')
      $productField.find('.lights-message').removeClass('warning').text('')
      $productField.find('#product-authorization-message').text('')
      $productField.find('.usage-infos-container').hide()

    _retrieveValues: () ->
      interventionId = $('input#intervention_id').val()
      $plantInputs = $('.nested-cultivation').filter -> $(this).find("[data-selector-id='intervention_target_product_id']").first().selector('value')
      targetsData = $plantInputs.map ->
        {
          id: $(this).find("[data-selector-id='intervention_target_product_id']").first().selector('value'),
          shape: $(this).find('[data-map-editor]').val()
        }

      { targets_data: targetsData.toArray(), intervention_id: interventionId }


  usageDoseInfos =
    display: ($input, $productField) ->
      @._clear($input)
      usageId = $productField.find("[data-selector-id='intervention_input_usage_id']").next('.selector-value').val()
      return unless usageId
      values = @._retrieveValues($input, $productField)
      return unless values.product_id && values.quantity && values.dimension && values.targets_data

      $.getJSON "/backend/registered_phytosanitary_usages/#{usageId}/dose_validations", values, (data) =>
        @._displayDose($input, data)

    _displayDose: ($input, data) ->
      for key, value of data
        addedClass = if key == 'stop' then 'warning' else ''
        $input.closest('.controls').find('.lights').addClass("lights-#{key}")
        $input.closest('.controls').find('.lights-message').addClass(addedClass).text("#{value}")

    _clear: ($input) ->
      $input.closest('.controls').find('.lights').removeClass("lights-go lights-caution lights-stop")
      $input.closest('.controls').find('.lights-message').removeClass("warning")

    _retrieveValues: ($input, $productField) ->
      productId = $productField.find("[data-selector-id='intervention_input_product_id']").first().selector('value')
      quantity = $input.val()
      dimension = $input.parent().find('select option:selected').val()
      targetsData = $('.nested-cultivation').map ->
        shape: $(this).find('[data-map-editor]').val()

      { product_id: productId, quantity: quantity, dimension: dimension, targets_data: targetsData.toArray() }


  # Update products infos on target remove
  $(document).on 'cocoon:after-remove', '.nested-targets', ->
    $("[data-selector-id='intervention_input_product_id']").trigger('selector:change')

  $(document).on 'cocoon:after-remove', '.nested-inputs', ->
    productsInfos.display()

  # Re-trigger all filters on target change
  $(document).on 'selector:change', "[data-selector-id='intervention_target_product_id']", ->
    $("[data-selector-id='intervention_input_product_id']").trigger('selector:change')

  $(document).on 'selector:change', "[data-selector-id='intervention_input_usage_id']", ->
    productsInfos.display()

  # Refresh usages, allowed mentions and badges on product update
  $(document).on 'selector:change', "input[data-selector-id='intervention_input_product_id']", ->
    productsInfos.display()
    $usageInput = $(this).closest('.nested-plant_medicine').find("[data-selector-id='intervention_input_usage_id']").first()
    if $(this).val() != ''
      $usageInput.attr('disabled', false)

  # Update usage details on usage change
  $(document).on 'selector:change', "[data-selector-id='intervention_input_usage_id']", ->
    usageMainInfos.display($(this), $(this).closest('.nested-plant_medicine'))

  # Update allowed doses on quantity change
  $(document).on 'input change', "input[data-intervention-field='quantity-value']", ->
    usageDoseInfos.display($(this), $(this).closest('.nested-plant_medicine'))


) ekylibre, jQuery
