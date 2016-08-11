module OmniAuth
  module Strategies
    class Doorkeeper < OmniAuth::Strategies::OAuth2
      option :client_options, site: 'http://localhost:3000',
                              authorize_path: '/oauth/authorize'

      def callback_url
        full_host + script_name + callback_path
      end
    end
  end
end
