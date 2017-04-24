((E, $) ->
  'use strict'

  $(document).ready ->
    E.accounts.changeUnmarkVisibility()

    $('#letters-visibility').on 'click', (e) ->
      E.accounts.changeUnmarkVisibility()

    $('#label-letters-visibility').on 'click', (e) ->
      if $('#letters-visibility').is(':checked')
        $('#letters-visibility').prop('checked', false)
      else
        $('#letters-visibility').prop('checked', true)

      E.accounts.changeUnmarkVisibility()

  E.accounts =
    changeUnmarkVisibility: ->
      unmarkLines = $('.active-list .unmark').closest('tr')

      if unmarkLines.is(':visible')
        unmarkLines.hide()
      else
        unmarkLines.show()



) ekylibre, jQuery
