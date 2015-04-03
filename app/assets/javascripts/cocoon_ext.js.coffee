((E, $) ->
  'use strict'

  # Add class on removed item
  $(document).on "cocoon:before-remove", "*", (event, item)->
    item.removeClass("nested-fields").addClass("removed-nested-fields") if item.hasClass("nested-fields")
    true

) ekylibre, jQuery
