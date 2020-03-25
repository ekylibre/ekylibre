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
          @._displayBadge($productField, infos.state, infos.check_conditions)
          @._displayMessages($productField, infos.messages)

    _displayAllowedMentions: ($productField, allowedMentions) ->
      $productField.find('span.allowed-mentions').insertAfter($productField.find('.intervention_inputs_product .selector'))
      for mention in allowedMentions
        $productField.find("##{mention}").show()

    _displayBadge: ($productField, state, checkConditions) ->
      new StateBadgeSet($productField.find('#intervention-products-badges')).setState(state)
      $productField.find('.input-authorization__text').show() if checkConditions

    _displayMessages: ($productField, messages) ->
      $productField.find('#product-authorization-message').html(messages.join('<br>'))

    _clear: ($productField) ->
      $productField.find('.allowed-mentions img').each -> $(this).hide()
      new StateBadgeSet($productField.find('#intervention-products-badges')).setState(null)
      $productField.find('.input-authorization__text').hide()

    _retrieveValues: () ->
      targetsData = Array.from(document.querySelectorAll('.nested-cultivation')).map (element) =>
        id: $(element).find("[data-selector-id='intervention_target_product_id']").next('.selector-value').val()
        shape: $(element).find('[data-map-editor]').val()

      productsData = Array.from(document.querySelectorAll(".nested-plant_medicine")).map (element) =>
        product_id: element.querySelector('.intervention_inputs_product input.selector-value').value
        usage_id: element.querySelector('.intervention_inputs_usage input.selector-value').value
        quantity: element.querySelector('.intervention_inputs_quantity input').value
        dimension: element.querySelector('.intervention_inputs_quantity select').value

      { products_data: productsData, targets_data: targetsData }

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
        if key == "usage_conditions" && value != null
          value = value.replace(/\n/, '<br />')

        $productField.find("[data-usage-attribute='#{key}']").html(value || '-')

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
    display: ($quantityInput, $productField) ->
      @._clearLights($quantityInput)
      usageId = $productField.find("[data-selector-id='intervention_input_usage_id']").next('.selector-value').val()
      return unless usageId
      values = @._retrieveValues($quantityInput, $productField)
      return unless values.product_id && values.quantity && values.dimension && values.targets_data

      $.getJSON "/backend/registered_phytosanitary_usages/#{usageId}/dose_validations", values, (data) =>
        @._displayDose($quantityInput, data)

    _displayDose: ($input, data) ->
      for key, value of data.dose_validation
        addedClass = if key == 'stop' then 'warning' else ''
        $input.closest('.controls').find('.lights').addClass("lights-#{key}")
        $input.closest('.controls').find('.lights-message').addClass(addedClass).text("#{value}")

    _clearLights: ($input) ->
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
  # And compute authorization badge again
  $(document).on 'input change', "input[data-intervention-field='quantity-value']", ->
    productsInfos.display()
    usageDoseInfos.display($(this), $(this).closest('.nested-plant_medicine'))


) ekylibre, jQuery
