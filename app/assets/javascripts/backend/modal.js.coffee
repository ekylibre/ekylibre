# This module permits to execute actions on modal

((E, $) ->
  'use strict'

  class Modal

    constructor: (selector) ->
      @selector = selector
      @modal = $("#{selector}")
      @modalHeader = $(@modal).find('.modal-header')
      @modalBody = $(@modal).find('.modal-body')
      @modalFooter = $(@modal).find('.modal-footer')

    resetModal: ->
      $(@modalHeader).find('> *:not(".close")').remove()
      $(@modalBody).empty()
      $(@modalFooter).empty()

    getHeader: ->
      return @modalHeader

    getBody: ->
      return @modalBody

    getFooter: ->
      return @modalFooter


  E.modal = Modal

) ekylibre, jQuery
