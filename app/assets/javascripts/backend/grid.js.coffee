(($) ->
  "use strict"

  $(document).on "click", "*[data-grid]", ->
    element = this
    console.log "Request fullscreen"
    console.log element
    if element.requestFullscreen
      element.requestFullscreen()
    else if element.requestFullScreen
      element.requestFullScreen()
    else if element.msRequestFullscreen?
      element.msRequestFullscreen()
    else if element.mozRequestFullScreen?
      element.mozRequestFullScreen()
    else if element.webkitRequestFullscreen?
      element.webkitRequestFullscreen()
    else
      console.warn "Cannot request fullscreen"

) jQuery

