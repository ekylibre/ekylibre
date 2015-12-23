((E, $) ->
  'use strict'

  # Add class on removed item
  $(document).on "cocoon:before-remove", "*", (event, item)->
    item.removeClass("nested-fields").addClass("removed-nested-fields") if item.hasClass("nested-fields")
    true

  # Manage minimum/maximum
  $(document).behave 'load cocoon:after-remove cocoon:after-insert', ".nested-association[data-association-insertion-minimum]", (event)->
    item = $(this)
    minimum = item.data('association-insertion-minimum')
    removers = item.find('> .nested-fields > .nested-remove')
    if item.children('.nested-fields').length <= minimum
      removers.hide()
    else
      removers.show()
    true

  # Manage minimum/maximum
  $(document).behave 'load cocoon:after-remove cocoon:after-insert', ".nested-association[data-association-insertion-maximum]", (event)->
    item = $(this)
    maximum = item.data('association-insertion-maximum')
    inserter = item.find('> .links')
    if item.children('.nested-fields').length >= maximum
      inserter.hide()
    else
      inserter.show()
    true

) ekylibre, jQuery
