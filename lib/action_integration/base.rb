module ActionIntegration
  # Base for any Integration
  class Base
    extend Protocols

    attr_reader :call

    include_protocol ActionIntegration::Protocols::HTML
    include_protocol ActionIntegration::Protocols::JSON
    include_protocol ActionIntegration::Protocols::Savon

    def initialize(call)
      # Call object to which we'll delegate the http requests making up
      # the api calls
      @call = call
    end

    def self.calls(*called_methods)
      # Each method in the "calls" parameters corresponds to a Call to an API
      # therefore for each of them we define a class method that will initialize
      # a Call object which will actually call the method.
      called_methods.each do |method|
        singleton_class.instance_exec(method) do
          define_method(method) do |*args|
            ::Call.new(
              integration_name: self,
              name: method,
              arguments:   args
            )
          end
        end
      end
    end

    def self.run(method_name = nil, every: nil, &block)
      raise ArgumentError, 'Please use either a method or a block at a time.' if block_given? && method_name.present?
      raise ArgumentError, 'Please specify either a method or a block.' unless method_name.present? || block_given?
      raise ArgumentError, 'Please specify a frequency.' unless every.present?
      raise ArgumentError, 'Invalid frequency.' unless [:day, :hour].include? every
      proc = lambda do
        begin
          to_execute = block || send(method_name).method(:execute)
          to_execute.call
        rescue ServiceNotIntegrated
          Rails.logger.info "Integration not present on tenant #{Ekylibre::Tenant.current}".yellow
        end
      end
      Ekylibre::Hook.subscribe("every_#{every}", proc)
    end

    # Check #####

    def self.check_connection(account = nil, &block)
      calls :check
      check(account).execute(&block)
    end

    def self.on_check_success(&block)
      Ekylibre::Hook.subscribe("#{integration_name.underscore}_check_successful", &block)
    end

    def self.on_check_error(&block)
      Ekylibre::Hook.subscribe("#{integration_name.underscore}_check_errored", &block)
    end

    def self.check
      raise NotImplementedError
    end

    #############

    def self.find_integration(type)
      descendants.select { |caller| caller.name.demodulize == type.to_s.camelize + 'Integration' }.first
    end

    def self.integration_name
      name.underscore
          .split('/')
          .last
          .split('_')[0...-1]
          .join('_')
          .camelize
    end

    def self.auth_type
      @auth_type || :check
    end

    def self.auth(type)
      @auth_type = type
      yield if block_given?
    end

    def self.parameters
      @parameters || []
    end

    def self.parameter(name)
      @parameters ||= []
      @parameters << name
    end

    def fetch_account(integration_account = nil)
      user_account = integration_account
      user_account &&= Integration.new(user_account)
      user_account ||= ::Integration.find_by_nature(self.class.integration_name.underscore)

      raise ServiceNotIntegrated unless user_account
      self.class.parameters.each do |p|
        raise IntegrationParameterEmpty, p if user_account.parameters[p.to_s].blank?
      end

      user_account
    end
  end
end
