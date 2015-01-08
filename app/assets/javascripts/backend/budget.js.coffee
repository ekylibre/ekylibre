(($) ->
  'use strict'

  $(document).on 'click keyup', "a[data-budget-add='support']", ->
    $(this).closest('table').find('tr.appendable').each ->
      $(this).find('td:last').before('<td>foo</td>')
    return false

  return
) jQuery
