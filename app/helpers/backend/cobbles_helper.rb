module Backend
  module CobblesHelper
    def async_cobble(type, options = {}, html_options = {})
      url = options[:params] || {}
      url = url_for(url.merge(controller: "backend/cobbles/#{type}_cobbles", action: :show))
      async_cobble = options[:cobble].cobble type do
                       async_content(url)
                     end
    end
  end
end
