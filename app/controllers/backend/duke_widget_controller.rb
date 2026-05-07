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
        }
      }
    end

    private

      def duke_ws_url
        ENV.fetch('DUKE_WS_URL', 'ws://localhost:8000/ws')
      end
  end
end
