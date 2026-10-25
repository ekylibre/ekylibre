module Backend
  # Returns the runtime configuration consumed by the Duke chat widget JS.
  # Token and tenant are tied to the authenticated session and rendered
  # only once per chat-open, never embedded in HTML pages.
  class DukeWidgetController < Backend::BaseController
    def show
      # Defense in depth: Backend::BaseController#authenticate_user! covers
      # us, but JSON-only requests can slip through without a redirect, so
      # we make the nil case explicit.
      return render(json: { error: 'unauthorized' }, status: :unauthorized) unless current_user

      user = current_user
      tenant = Apartment::Tenant.current

      render json: {
        ws_url: duke_ws_url,
        token: user.authentication_token,
        tenant: tenant,
        locale: user.language.presence || I18n.locale.to_s,
        user: {
          id: user.id,
          full_name: user.full_name,
          email: user.email
        },
        stt_server_enabled: stt_server_enabled?,
        stt_url: stt_server_enabled? ? duke_stt_url : nil
      }
    end

    private

      def duke_ws_url
        ENV.fetch('DUKE_WS_URL', 'ws://localhost:8000/ws')
      end

      # Whisper fallback transcription endpoint. Defaults to the same host as
      # `DUKE_WS_URL` with the scheme swapped (ws → http) and `/ws` stripped.
      # Override with `DUKE_HTTP_URL` when Duke is reverse-proxied behind a
      # different path/host than the WS.
      def duke_stt_url
        base = ENV.fetch('DUKE_HTTP_URL') do
          duke_ws_url
            .sub(%r{\Aws://}, 'http://')
            .sub(%r{\Awss://}, 'https://')
            .sub(%r{/ws\z}, '')
        end
        "#{base}/api/v1/stt/transcribe"
      end

      def stt_server_enabled?
        ActiveModel::Type::Boolean.new.cast(ENV['DUKE_STT_SERVER_ENABLED']) == true
      end
  end
end
