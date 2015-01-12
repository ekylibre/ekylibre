(($) ->
  'use strict'
  $(document).on 'click keyup', "a[data-association='support']", ->
    $("a[data-association='item']").click()
    return false

  return
) jQuery
