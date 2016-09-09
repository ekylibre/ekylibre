module Backend
  module IntegrationsHelper
    def integration_logo_path(integration_name, size: :small)
      integration = ActionIntegration::Base.find_integration(integration_name)

      possible_names = integration.parents.map(&:name)
      possible_names = possible_names.prepend(integration_name)
      possible_names = possible_names.map(&:underscore)
      possible_names = possible_names.map(&:to_s)

      assets = Rails.application.assets
      existing_assets = possible_names.map { |name| assets.find_asset("integrations/#{name}") }

      existing_assets.compact.first.logical_path
    end
end
end
