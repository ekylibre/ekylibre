module Backend
  module AsyncContentsHelper
    def async_content(url, html_options = {})
      content_tag(:div, nil, html_options.merge(
                               data: {
                                 async_content: url,
                                 async_content_empty_message: :no_data.tl,
                                 async_content_error_message: :internal_error.tl
                               }
      ))
    end
  end
end
