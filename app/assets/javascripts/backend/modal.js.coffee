# This module permits to execute actions on modal

((E, $) ->
  'use strict'

  class Modal

    constructor: (selector) ->
      @selector = selector
      @modal = $(selector)
      @modalHeader = @modal.find('.modal-header')
      @modalBody = @modal.find('.modal-body')
      @modalFooter = @modal.find('.modal-footer')

    resetModal: ->
      @modalHeader.find('> *:not(".close")').remove()
      @modalBody.empty()
      @modalFooter.empty()

    removeModalContent: ->
      this.getModalContent().empty()

    getModal: ->
      console.warn("Modal#getModal is deprecated, use getElement instead")
      return @getElement()

    getElement: ->
      return @modal

    getModalContent: ->
      console.warn("Modal#getModalContent is deprecated, use getContent instead")
      return @getContent()

    getContent: ->
      return @modal.find(".modal-content")

    setContent: (content) ->
      Promise.resolve(content)
        .then (content) => @getContent().html(content)

    getHeader: ->
      return @modalHeader

    getBody: ->
      return @modalBody

    getFooter: ->
      return @modalFooter

    show: ->
      @modal.modal 'show'

    hide: ->
      @modal.modal 'hide'

    close: ->
      @hide()
      @setContent('')

  E.modal = Modal

  # Shortcut to open and set content of the modal
  # Returns a promise that resolves to the modal
  E.modal.open = (selector, content) =>
    modal = new Modal(selector)
    modal.setContent(content)
      .then(=> modal.show())
      .then(=> modal).catch ((e) => Promise.reject({modal: modal, error: e}))

) ekylibre, jQuery
