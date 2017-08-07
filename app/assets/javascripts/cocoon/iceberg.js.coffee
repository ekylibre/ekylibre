(($) ->
  'use strict'

  class Iceberg
    constructor: (@line, mode) ->
      # console.log 'this', this
      @display = @line.find('.item-display')

      @_bindButtons(@newForm())

      @_bindEditEvent()

      unless mode is "add" or @line.find('.error').length > 0
        @display.removeClass('hidden')
        @oldForm().remove()
        @_bindSelectorsInitialization()
        @newForm().addClass('hidden')
        @setFormSubmitable()

    _bindButtons: (form) ->
      # console.log '_bindButtons:this', this
      that = this
      $(form).find('button[data-validate="item-form"]').each ->
        $(this).click (event) ->
          that.validate()
          event.preventDefault()

      $(form).find('button[data-cancel="item-form"]').each ->
        $(this).click (event) ->
          that.cancel()
          event.preventDefault()

    _bindEditEvent: ->
      @line.find('*[data-edit="item-form"]').click =>
        # console.log @line, this
        @display.addClass('hidden')

        clone = @oldForm().clone()
        clone.insertBefore(@oldForm())
        clone.trigger('cocoon:after-insert')
        clone.removeClass('hidden')
        @_bindButtons(@newForm())
        @setFormSubmitable()
        @toggleTransporterInput()

    _bindSelectorsInitialization: ->
      that = this
      form = @newForm()
      form.find('*[data-selector]').parent().each ->
        $(this).on 'selector:change', ->
          that.interpolate(form)

    validate: ->
      # console.log 'validate:this', this
      @interpolate()

      @display.removeClass('hidden')
      @oldForm().remove()
      @newForm().addClass('hidden')
      @setFormSubmitable()

    interpolate: (form = @newForm()) ->
      @display.find('*[data-item-value]').each ->
        element = $(this)
        unless element.closest("*[data-item-loop]").length >= 1
          target = $(form).find(element.data("item-value")).first()
          if target.is("input")
            if target.is("input[type='radio']")
              value = target.parent().text()
            else if target.is("input[type='checkbox']")
              if target.is('input[data-warn-if-checked]:checked')
                value = $('<span class="warn-message"></span>').html(target.data('warn-if-checked'))
              else
                value = ""
            else
              value = target.val()
          else
            value = target.html()
        element.html(value)

    cancel: ->
      # console.log 'cancel:this', this
      if @line.find('.nested-item-form').length is 1
        @line.remove()
      else
        @display.removeClass('hidden')
        @newForm().remove()
      @setFormSubmitable()

    setFormSubmitable: ->
      if $('.nested-item-form:visible').length >= 1
        $('.form-actions .primary').attr("disabled",true)
      else
        $('.form-actions .primary').attr("disabled",null)

    toggleTransporterInput: ->
      @line.find('*[data-field="item-delivery-mode"]').click (event) =>
        target = event.target
        if target.value == 'transporter'
          @line.find('.transporter-delivery-mode').removeClass('hidden')
        else
          @line.find('.transporter-delivery-mode').addClass('hidden')

    oldForm: ->
      # console.log 'oldForm:this', this
      @line.find('.nested-item-form:hidden')

    newForm: ->
      # console.log 'newForm:this', this
      @line.find('.nested-item-form:visible')


  $(document).ready ->
    $('*[data-iceberg]').each ->
      new Iceberg($(this))

    $('table.list').on 'cocoon:after-insert', (event, inserted) ->
      new Iceberg($(inserted), "add") if inserted?
      $('*[data-unit-name]').each ->
        $(this).find('.item-population-unit-name').html($(this).attr('data-unit-name'))

    # app = new Vue {
    #   el: '#app',
    #   data: {
    #     storings: [],
    #     selected: 'dfsdf'
    #   }
    #   methods: {
    #     fillStoringsTab: -> {
    #       storings.push({
    #         quantity: 8
    #         })
    #     }
    #   }
    # }


) jQuery
