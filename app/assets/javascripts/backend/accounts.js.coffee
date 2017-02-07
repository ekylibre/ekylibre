((E, $) ->
  'use strict'

  $(document).ready ->
    $('#lettersVisibility').on 'click', (e) ->
      E.accounts.changeUnmarkVisibility() 

    $('#labelLettersVisibility').on 'click', (e) ->
      if $('#lettersVisibility').is(':checked')
        $('#lettersVisibility').prop('checked', false)
      else
        $('#lettersVisibility').prop('checked', true)

      E.accounts.changeUnmarkVisibility() 

  E.accounts =
    changeUnmarkVisibility: ->
      unmarkLines = $('.active-list .unmark').closest('tr')

      if unmarkLines.is(':visible')
        unmarkLines.hide()
      else
        unmarkLines.show()



) ekylibre, jQuery
