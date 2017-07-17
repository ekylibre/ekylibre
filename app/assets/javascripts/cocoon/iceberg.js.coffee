(($) ->
  'use strict'

  class Iceberg
    constructor: (@line) ->
      # console.log 'this', this
      @display = @line.find('.item-display')

      @_bindButtons(@newForm())

      @line.find('*[data-edit="item-form"]').click =>
        @display.addClass('hidden')

        clone = @oldForm().clone()
        clone.insertAfter(@oldForm())
        clone.trigger('cocoon:after-insert')
        clone.removeClass('hidden')
        @_bindButtons(@newForm())

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

    validate: ->
      # console.log 'validate:this', this
      that = this
      @display.find('*[data-item-value]').each ->
        element = $(this)
        target = $(that.newForm()).find(element.data("item-value")).first()
        if target.is("input")
          value = target.val()
        else
          value = target.html()
        element.html(value)

      @display.removeClass('hidden')
      @oldForm().remove()
      @newForm().addClass('hidden')

    cancel: ->
      # console.log 'cancel:this', this
      @display.removeClass('hidden')
      @newForm().remove()

    oldForm: ->
      # console.log 'oldForm:this', this
      @line.find('.nested-item-form:hidden')

    newForm: ->
      # console.log 'newForm:this', this
      @line.find('.nested-item-form:visible')

  $(document).ready ->
    $('table.list').on 'cocoon:after-insert', (event, inserted) ->
      new Iceberg($(inserted))
) jQuery
