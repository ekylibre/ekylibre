# Cells management
# 
(($) ->
  $(document).ready ->
    $("*[data-cell]").each (index) ->
      element = $(this)
      element.addClass("loading")
      $.ajax(element.data("cell"), {
        dataType: "html",
        success: (data, status, request) ->
          element.removeClass("loading")
          element.html(data)
          element.trigger('cell:load')
        error: (request, status, error) ->
          alert("#{status} on cell (#{element.data('cell')}): #{error}")
          console.log("Error while retrieving cell content")
          element.html(request.responseXML)
      })

  true
) jQuery
