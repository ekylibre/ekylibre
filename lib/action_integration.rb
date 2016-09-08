module ActionIntegration
  mattr_accessor :config
  autoload :Base,               'action_integration/base'
  autoload :Configuration,      'action_integration/configuration'
  autoload :Parameters,         'action_integration/parameters'
  autoload :Protocols,          'action_integration/protocols'
  autoload :Response,           'action_integration/response'

  self.config = ActionIntegration::Configuration.new

  class ServiceNotIntegrated < StandardError; end
  class IntegrationParameterEmpty < StandardError; end
end
