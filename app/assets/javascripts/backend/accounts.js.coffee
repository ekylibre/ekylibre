((E, $) ->
  'use strict'

  $(document).ready ->
    if $('#letters-visibility').is(':checked')
      E.accounts.changeUnmarkVisibility()

    $('#letters-visibility').on 'click', (e) ->
      E.accounts.changeUnmarkVisibility()

    $('#label-letters-visibility').on 'click', (e) ->
      if $('#letters-visibility').is(':checked')
        $('#letters-visibility').prop('checked', false)
      else
        $('#letters-visibility').prop('checked', true)

      $.ajax
        url: ($('#letters-visibility').data('preference-url'))
        type: 'PATCH'
        data: 
          checked: $('#letters-visibility').is(':checked')
        success: (data, status, request) ->
          console.log data

      E.accounts.changeUnmarkVisibility()

  E.accounts =
    changeUnmarkVisibility: ->
      unmarkLines = $('.active-list .unmark').closest('tr')

      if unmarkLines.is(':visible')
        unmarkLines.hide()
      else
        unmarkLines.show()



) ekylibre, jQuery
