((E, $) ->
  'use strict'

  class Iceberg
    constructor: (@line, mode) ->
      @display = @line.find('.item-display')

      @_bindButtons(@newForm())

      @_bindEditEvent()

      @toggleInputVisibility()

      @setFormSubmitable()

      @setCocoonFormSubmitable()

      @retrievePreviousItemValue()

      @line.trigger("iceberg:inserted", [@line])

      $(@line).data('_iceberg', this)

      unless mode is "add" or @line.find('.error').length > 0 or @line.find('.prefilled').length > 0
        @display.removeClass('hidden')
        @oldForm().remove()
        @bindSelectorsInitialization (form) =>
          this.interpolate(form)
        @newForm().addClass('hidden')
        @setFormSubmitable()

    _bindButtons: (form) ->
      that = this
      $(form).find('[data-validate="item-form"]').each ->
        $(this).click (event) ->
          that.validate()
          event.preventDefault()

      $(form).find('[data-cancel="item-form"]').each ->
        $(this).click (event) ->
          that.cancel()
          event.preventDefault()

    _bindEditEvent: ->
      @line.find('*[data-edit="item-form"]').click =>
        $(document).data('edited-mode', true)
        @display.addClass('hidden')
        clone = @oldForm().clone()
        clone.insertBefore(@oldForm())
        clone.trigger('cocoon:after-insert')
        clone.removeClass('hidden')
        @_bindButtons(@newForm())
        @_bindEdition(@oldForm())
        @_bindEdition(@newForm())
        @toggleInputVisibility()
        @setFormSubmitable()
        @setCocoonFormSubmitable()
        @line.trigger "iceberg:inserted"
        value = @line.first().find('[data-item-value="input.order-unit-amount"]').text()
        @line.first().find('.nested-item-form').find('.order-unit-amount').val(value)

    _bindEdition: (form) ->
      form.find('input').on 'input', =>
        @setFormSubmitable()
        @setCocoonFormSubmitable()

    bindSelectorsInitialization: (callback) ->
      form = @newForm()
      form.find('*[data-selector]').parent().each ->
        $(this).on 'selector:change selector:set selector:initialize', ->
          callback(form)

    validate: ->
      @interpolate()

      @display.removeClass('hidden')
      @oldForm().remove()
      @newForm().addClass('hidden')
      @setFormSubmitable()
      @line.trigger('iceberg:validated', {iceberg: @, line: @line})

    interpolate: (form = @newForm()) ->
      @display.find('*[data-item-value]').each ->
        element = $(this)
        target = $(form).find(element.data("item-value")).first()
        if target.is("input[data-use-as-value]")
          if target.val() == target.data("with-value")
            value = $(form).find(target.data("use-as-value")).val()
          else if target.is("input[type='radio']")
            value = target.parent().text()
          else if target.is("input[type='checkbox']")
            if target.is('input[data-warn-if-checked]:checked')
              value = $('<span class="warn-message"></span>').html(target.data('warn-if-checked'))
            else
              value = ""
          else
            value = target.val()
        else if target.is("input[data-interpolate-if-input]")
          dependingInput = $(form).find(target.data('interpolate-if-input'))
          if dependingInput.is("input[type='checkbox']")
            if dependingInput.is(':checked') == target.data('with-value')
              value = target.val()
            else
              value = ""
        else if target.is("input:not([data-use-as-value])")
          if target.is("input[type='radio']")
            value = target.parent().text()
          else if target.is("input[type='checkbox']")
            if target.is('input[data-warn-if-checked]:checked')
              value = $('<span class="warn-message"></span>').html(target.data('warn-if-checked'))
            else
              value = ""
          else
            value = target.val()
        else if target.is('[data-interpolate-data-attribute]')
          value = target.data('interpolate-data-attribute')
        else
          value = target.html()
        element.html(value)
      @interpolateStoring()

    cancel: ->
      if @line.find('.nested-item-form').length is 1
        @line.remove()
      else
        @display.removeClass('hidden')
        @newForm().remove()
      @setFormSubmitable()
      @line.trigger('iceberg:cancelled', {iceberg: @, line: @line})

    setFormSubmitable: ->
      if $('.nested-item-form:visible').length >= 1
        $('.form-actions .primary').attr("disabled",true)
      else
        $('.form-actions .primary').attr("disabled",null)

    setCocoonFormSubmitable: ->
      E.toggleValidateButton(@line)
      E.setStorageUnitName(@line)

    toggleInputVisibility: ->
      @line.find('input[data-input-to-show]').each (index, input) =>
        if $(input).is("input[type='checkbox']")
          if $(input).is(':checked') == $(input).data('with-value')
            @line.find($(input).data('input-to-show')).removeClass('hidden')
        else if $(input).is("input[type='radio']:checked")
          if $(input).val() == $(input).data('with-value')
            @line.find($(input).data('input-to-show')).removeClass('hidden')
      @line.find('input[data-input-to-show]').click (event) =>
        element = $(event.target)
        if element.is("input[type='checkbox']")
          if element.is(':checked') == element.data('with-value')
            @line.find(element.data('input-to-show')).removeClass('hidden')
          else
            @line.find(element.data('input-to-show')).addClass('hidden')
        else if element.is("input[type='radio']")
          if element.val() == element.data('with-value')
            @line.find(element.data('input-to-show')).removeClass('hidden')
          else
            @line.find(element.data('input-to-show')).addClass('hidden')

    oldForm: ->
      @line.find('.nested-item-form:hidden')

    newForm: ->
      @line.find('.nested-item-form:visible')

    interpolateStoring: ->
      zones = []
      form = if @newForm().length > 0 then @newForm() else @oldForm()
      form_nature = if @line.find('#storing-display').length > 0 then 'reception' else 'purchase'
      form.find('.storing-fields').not('.removed-nested-fields').each ->
        zones.push
          quantity: $(this).find('input.storing-quantity').val()
          unit: if form_nature == 'reception' then $(this).find('input.reception-conditionning').val() else $(this).find('input.invoice-conditioning').val()
          name: $(this).find('input.parcel-item-storage').val()         

      form.find('.role-row--non-merchandise').each ->
        zones.push
          quantity: $(this).find('input.reception-quantity').val()
          unit: $(this).find('[data-coefficient]').data('interpolate-data-attribute')
      data = zones: zones
      @line.find('#conditioning-display').html(storing_display_template(zones, 'conditioning'))
      @line.find('#storing-display').html(storing_display_template(zones, 'zone'))
      if form_nature == 'reception'
        @line.find('.quantity-column span.population').html(zones[0].quantity)
      else
        @line.find('.conditioning-column label').html(zones[0].unit)

    retrievePreviousItemValue: ->
      line = @line
      all_lines = line.parent().find('.nested-fields')
      if all_lines.length > 1
        input_values_hash = {}
        all_lines.first().find('*[data-remember]').each ->
          if $(this).is('.selector-search')
            input_values_hash[$(this).data('remember')] = $(this).parent().find('.selector-value').val()
        for item in Object.keys(input_values_hash)
          line.find('*[data-remember=' + item + ']').val(input_values_hash[item])

  storing_display_template = (zones, name) =>
    zones.map((zone) =>
      val = if name == 'zone' then zone.name else "#{zone.quantity} #{zone.unit}"
      """
        <p>
          <span class="storage-#{name}">#{val}</span>
        </p>
      """
      ).reduce(((a, b) -> a + b), '')
      
  $(document).ready ->
    $('*[data-iceberg]').each ->
      mode = "add" if typeof($(this).data("display-items-form")) != 'undefined'
      iceberg = new Iceberg($(this), mode)

    $('table.list').on 'cocoon:after-insert', (event, inserted) ->
      iceberg = new Iceberg($(inserted), "add") if inserted?

      $('*[data-unit-name]').each ->
        $(this).find('.item-population-unit-name').html($(this).attr('data-unit-name'))

) ekylibre, jQuery
