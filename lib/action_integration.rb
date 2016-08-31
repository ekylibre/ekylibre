module ActionIntegration
  autoload :Base,               'action_integration/base'
  autoload :Protocols,          'action_integration/protocols'
  autoload :Response,           'action_integration/response'

  class ServiceNotIntegrated < StandardError; end
  class IntegrationParameterEmpty < StandardError; end
end
