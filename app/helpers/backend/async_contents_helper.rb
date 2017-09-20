module Backend
  module AsyncContentsHelper
    def async_content(type, options = {}, html_options = {})
      url = options[:params] || {}
      content_tag(:div, nil, html_options.merge(
                               data: {
                                 async_content: url_for(url.merge(controller: "backend/async_contents/#{type}_async_contents", action: :show)),
                                 async_content_empty_message: :no_data.tl,
                                 async_content_error_message: :internal_error.tl
                               }
      ))
    end
  end
end
