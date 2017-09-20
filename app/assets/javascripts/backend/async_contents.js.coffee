#= require jquery.blank
#= require jquery-ui/widgets/sortable

(($) ->
  "use strict";
  $(document).ready ->
    $("*[data-async-content]").each (index) ->
      async_content_div = $(this)
      async_content_div.addClass("loading")
      async_content_div.html("<i class='cell-indicator'></i>")
      $.ajax
        url: async_content_div.data("async-content")
        dataType: "html"
        success: (data, status, request) ->
          async_content_div.removeClass("loading")
          if $.isBlank(data)
            async_content_div.addClass("blank")
            async_content_div.append($("<p class='cell-message'>#{async_content_div.data('async-content-empty-message')}</p>"))
            async_content_div.trigger('cell:empty')
          else
            async_content_div.html(data)
            async_content_div.trigger('cell:load')
            $(window).trigger('resize')
        error: (request, status, error) ->
          console.error("Error while retrieving #{async_content_div.data('async-content')} cell content: #{status} #{error}")
          async_content_div.removeClass("loading")
          async_content_div.addClass("errored")
          async_content_div.append($("<p class='cell-message'>#{async_content_div.data('async-content-error-message')}</p>"))
          async_content_div.trigger('cell:error')
  true
) jQuery
