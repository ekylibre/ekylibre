# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

(($) ->
  $(document).ready ->
    $("[data-cell]").each((index) ->
      element = $(this)
      element.addClass("loading")
      $.ajax(element.data("cell"), {
        dataType: "html",
        success: (data, status, request) ->
          element.removeClass("loading")
          element.html(data)
          true
      })
      true
    )
    true


  true
) jQuery
