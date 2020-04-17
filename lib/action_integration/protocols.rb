module ActionIntegration
  # 'Loader' of the protocols.
  module Protocols
    def include_protocol(protocol)
      # Reworking the module to have better methods.
      protocol.instance_methods.each do |m|
        method_with_format! protocol, m
      end

      ::Call.include(protocol)
      Rails.logger.info "#{protocol.name} included in Call.".yellow

      # Delegating all the request methods from ActionIntegration to its Call object.
      protocol.instance_methods.each do |m|
        delegate m, to: :call
        #Rails.logger.info "Caller method ##{method} delegated to Call object."
      end
    end

    private

    # Prefixes the method name with the name of the protocol
    # and makes it set the Call @format attribute to the protocol's.
    # Example with HTML#get :
    #   - the method becomes Call#get_html once the module is included
    #   - Base#execute_request will be able to log the request as a HTML one.
    def method_with_format!(protocol, m)
      # Protcols::JSON -> "json"
      protocol_name = protocol.name.demodulize.downcase
      format_overridden = protocol.constants.include?(:FORMAT)
      format = format_overridden ? protocol.const_get(:FORMAT) : protocol_name
      original_method = protocol.instance_method(m)

      protocol.send(:define_method, "#{m}_#{protocol_name}") do |*args, &block|
        @format = format
        original_method.bind(self).call(*args, &block)
      end

      # Removes method from module once we have set up the prefixed version.
      protocol.send :remove_method, m
    end
  end
end
