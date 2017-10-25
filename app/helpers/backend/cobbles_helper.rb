module Backend
  module CobblesHelper
    def async_cobble(type, options = {})
      url = options[:params] || {}
      url = url_for(url.merge(controller: "backend/cobbles/#{type}_cobbles", action: :show))
      options[:cobble].cobble type do
        yield if block_given?
        async_content(url)
      end
    end
  end
end
