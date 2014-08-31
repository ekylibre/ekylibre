#= require jquery.blank
# Cells management
#
(($) ->
  $(document).ready ->
    $("*[data-cell]").each (index) ->
      element = $(this)
      element.addClass("loading")
      element.html("<i class='cell-indicator'></i>")
      $.ajax(element.data("cell"), {
        dataType: "html",
        success: (data, status, request) ->
          element.removeClass("loading")
          if $.isBlank(data)
            element.removeClass("loading")
            element.addClass("blank")
            element.trigger('cell:empty')
          else
            element.html(data)
            element.trigger('cell:load')
        error: (request, status, error) ->
          # alert("#{status} on cell (#{element.data('cell')}): #{error}")
          console.log("Error while retrieving #{element.data('cell')} cell content: #{error}")
          element.removeClass("loading")
          element.addClass("errored")
          element.html(request.responseXML)
          element.trigger('cell:error')
      })

  true
) jQuery
