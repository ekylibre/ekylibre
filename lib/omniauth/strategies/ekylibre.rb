module OmniAuth
  module Strategies
    class Ekylibre < OmniAuth::Strategies::OAuth2
      option :client_options,
             site: ENV.fetch('EKYLIBRE_OAUTH2_SITE', nil),
             authorize_path: ENV.fetch('EKYLIBRE_OAUTH2_AUTHORIZE_PATH', nil)

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
        @raw_info ||= access_token.get(ENV.fetch('EKYLIBRE_OAUTH2_API_ME_ENDPOINT', nil)).parsed
      end

      def invitation_token_param
        return '' unless request.params['invitation_token']

        "?invitation_token=#{request.params['invitation_token']}"
      end
    end
  end
end
