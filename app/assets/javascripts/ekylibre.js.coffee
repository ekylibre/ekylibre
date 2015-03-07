((E, $) ->
  "use strict"

  #
  # AJAX error handler
  E.ajaxErrorHandler = (request, status, error) ->
    if console.error?
      console.error "AJAX failure (#{status}): #{error}"
    else
      alert("AJAX failure (#{status}): #{error}")
      console.log "AJAX failure (#{status}): #{error}"
    return true

) ekylibre, jQuery
