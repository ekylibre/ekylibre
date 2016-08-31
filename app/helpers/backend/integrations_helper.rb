module Backend::IntegrationsHelper
  def integration_logo_path(integration_name, size: :small)
    integration = ActionIntegration::Base.find_integration(integration_name)

    possible_names = integration.parents.map(&:name)
    possible_names = possible_names.prepend(integration_name)
    possible_names = possible_names.map(&:underscore)

    image_files = possible_names.map do |name|
      images = Dir.glob(Rails.root.join('app', 'assets', 'images', 'integrations', '*'))
      image_names = images.map { |path| [File.basename(path, '.*'), File.basename(path)] }
      image_names.to_h["#{name}-#{size}"]
    end
    image_files.compact.first && 'integrations/'+image_files.compact.first
  end
end
