module Backend
  module IntegrationsHelper
    def integration_logo_path(integration_name, size: :small)
      integration = ActionIntegration::Base.find_integration(integration_name)

      keys = [integration_name] + integration.parents.map(&:name)
      possible_names = keys.map { |key| key.to_s.underscore }

      formats = %w(svg png)

      path = nil
      manifest = Rails.application.assets_manifest
      name = possible_names.detect do |name|
        formats.detect do |format|
          path = "integrations/#{name}.#{format}"
          manifest.find_logical_paths(path).any?
        end
      end
      paths = manifest.find_logical_paths(path).first
      paths.first
    end
  end
end
