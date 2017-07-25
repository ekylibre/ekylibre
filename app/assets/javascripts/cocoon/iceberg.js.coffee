(($) ->
  'use strict'

  class Iceberg
    constructor: (@line) ->
      # console.log 'this', this
      @display = @line.find('.item-display')

      @_bindButtons(@newForm())
      $('.form-actions .primary').attr("disabled",true)

      @edit()

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

    edit: ->
      @line.find('*[data-edit="item-form"]').click =>
        @display.addClass('hidden')

        clone = @oldForm().clone()
        clone.insertBefore(@oldForm())
        clone.trigger('cocoon:after-insert')
        clone.removeClass('hidden')
        @_bindButtons(@newForm())
        $('.form-actions .primary').attr("disabled",true)

    validate: ->
      # console.log 'validate:this', this
      that = this
      @display.find('*[data-item-value]').each ->
        element = $(this)
        target = $(that.newForm()).find(element.data("item-value")).first()
        if target.is("input")
          if target.is("input[type='radio']")
            value = target.parent().text()
          else
            value = target.val()
        else
          value = target.html()
        element.html(value)

      @display.removeClass('hidden')
      @oldForm().remove()
      @newForm().addClass('hidden')
      @isFormSubmitable()

    cancel: ->
      # console.log 'cancel:this', this
      if @line.find('.nested-item-form').length is 1
        @line.remove()
      else
        @display.removeClass('hidden')
        @newForm().remove()
      @isFormSubmitable()

    isFormSubmitable: ->
      if $('.nested-item-form:visible').length >= 1
        $('.form-actions .primary').attr("disabled",true)
      else
        $('.form-actions .primary').attr("disabled",null)

    oldForm: ->
      # console.log 'oldForm:this', this
      @line.find('.nested-item-form:hidden')

    newForm: ->
      # console.log 'newForm:this', this
      @line.find('.nested-item-form:visible')

  $(document).ready ->
    $('*[data-iceberg]').each ->
      new Iceberg($(this))
    $('*[data-iceberg]').on 'cocoon:after-insert', (event, inserted) ->
      new Iceberg($(inserted))
) jQuery
