(($) ->
  "use strict"

  $(document).on "mouseover", "*[data-simple-calendar] a.previous-month, *[data-simple-calendar] a.next-month", ->
    link = $(this)
    calendar = link.closest("*[data-simple-calendar]")
    link.attr("data-remote", "true")
      .attr("data-method", "get")
      .attr("data-update", "#" + calendar.attr("id"))
      .attr("data-update-mode", "closest")
    return

  return
) jQuery
