module OmniAuth
  module Strategies
    class Ekylibre < OmniAuth::Strategies::OAuth2
      option :client_options,
             site: ENV['EKYLIBRE_OAUTH2_SITE'],
             authorize_path: ENV['EKYLIBRE_OAUTH2_AUTHORIZE_PATH']

      uid do
        raw_info['uid']
      end

      info do
        {
          email: raw_info['email'],
          first_name: raw_info['first_name'],
          last_name: raw_info['last_name']
        }
      end

      def callback_url
        full_host + script_name + callback_path + invitation_token_param
      end

      def raw_info
        @raw_info ||= access_token.get(ENV['EKYLIBRE_OAUTH2_API_ME_ENDPOINT']).parsed
      end

      def invitation_token_param
        return '' unless request.params['invitation_token']
        "?invitation_token=#{request.params['invitation_token']}"
      end
    end
  end
end
