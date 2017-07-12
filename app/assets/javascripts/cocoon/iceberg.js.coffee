(($) ->
  'use strict'

  class Iceberg
    constructor: (@line) ->
      @display = @line.find('.item-display')

      bindButtons(newForm)

      @line.find('[data-edit="item-form"]').click ->
        @display.addClass('hidden')

        clone = oldForm.clone()
        clone.insertAfter(oldForm)
        clone.removeClass('hidden')
        bindButtons(newForm)

    bindButtons: (form) ->
      $(form).find('button[data-validate="item-form"]').each ->
        $(this).click (event) ->
          validate
          event.preventDefault()

      $(form).find('button[data-cancel="item-form"]').each ->
        $(this).click (event) ->
          cancel
          event.preventDefault()

    validate: ->
      @display.find('*[data-item-value]').each ->
        element = $(this)
        target = $(newForm).find(element.data("item-value")).first()
        if target.is("input")
          value = target.val()
        else
          value = target.html()
        element.html(value)

      @display.removeClass('hidden')
      oldForm.remove()
      newForm.addClass('hidden')

    cancel: ->
      @display.removeClass('hidden')
      newForm.remove()

    oldForm: ->
      @line.find('.nested-item-form:hidden')

    newForm: ->
      @line.find('.nested-item-form:visible')

  $(document).ready ->
    $('table.list').on 'cocoon:after-insert', (event, inserted) ->
      iceberg = Iceberg.new($(inserted))
) jQuery
