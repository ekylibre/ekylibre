#= require 'bootstrap/tooltip'
#= require 'bootstrap/popover'

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


  $(document).behave "load", "*[data-content]", () ->
    $(this).popover
      trigger: "hover"
      placement: "bottom"
      container: "#wrap"
      html: true
    return

  $(document).behave "load", "*[data-toggle='popover']", () ->
    $(this).popover
      trigger: "click"
      placement: "bottom"
      container: "#wrap"
      content: $($(this).attr("href")).html()
      html: true
    return false

  return
) jQuery
