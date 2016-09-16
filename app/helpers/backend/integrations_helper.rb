module Backend
  module IntegrationsHelper
    def integration_logo_path(integration_name, size: :small)
      "integrations/#{integration_name.to_s.underscore}.png"
    end
  end
end
