module ActionIntegration
  # 'Loader' of the protocols.
  module Protocols
    def include_protocol(protocol)
      # Reworking the module to have better methods.
      protocol.instance_methods.each do |method|
        method_with_format! protocol, method
      end

      ::Call.include(protocol)
      Rails.logger.info "#{protocol.name} included in Call.".yellow

      # Delegating all the request methods from ActionIntegration to its Call object.
      protocol.instance_methods.each do |method|
        delegate method, to: :call
        #Rails.logger.info "Caller method ##{method} delegated to Call object."
      end
    end

    private

    # Prefixes the method name with the name of the protocol
    # and makes it set the Call @format attribute to the protocol's.
    # Example with HTML#get :
    #   - the method becomes Call#get_html once the module is included
    #   - Base#execute_request will be able to log the request as a HTML one.
    def method_with_format!(protocol, method)
      # Protcols::JSON -> "json"
      protocol_name = protocol.name.demodulize.downcase
      format_overridden = protocol.constants.include?(:FORMAT)
      format = format_overridden ? protocol.const_get(:FORMAT) : protocol_name
      original_method = protocol.instance_method(method)

      protocol.send(:define_method, "#{method}_#{protocol_name}") do |*args, &block|
        @format = format
        original_method.bind(self).call(*args, &block)
      end

      # Removes method from module once we have set up the prefixed version.
      protocol.send :remove_method, method
    end
  end
end
