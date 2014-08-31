# Permit to test is avalue is blank
(($) ->
  'use strict'

  # Work like $.isArray, $.isFunction...
  $.isBlank = (obj) -> 
    return (!obj? or $.trim(obj) == "")

  true
) jQuery
