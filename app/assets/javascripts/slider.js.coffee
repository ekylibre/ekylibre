(($) ->
  'use strict'
  $.display = (value) ->
    console.log(value)

  $.load = ->
    $("*[data-slider]").each ->
      length = $(this).data("slider").crumbs.length
      $(this).slider
        min: 0
        max: length - 1
        values: $(this).data("slider").cursors
        slide: (event, ui) ->
          $.display(ui.value)
    return

  # events
  $(document).ready $.load
  true
) jQuery
