module ActionIntegration
  # Response object that includes the DSL methods.
  class Response
    attr_reader :code, :headers, :body
    attr_reader :state, :result

    def initialize(params)
      @code = params[:code]
      @headers = params[:headers]
      @body = params[:body]
      success(nil, true)
      redirect(nil, true)
      client_error(nil, true)
      server_error(nil, true)
    end

    def self.new_from_net(net_response)
      new(
        code: net_response.code,
        headers: net_response.to_hash,
        body: net_response.body
      )
    end

    def self.new_from_httpi(httpi_response)
      new(
        code: httpi_response.code,
        headers: httpi_response.headers,
        body: httpi_response.raw_body
      )
    end

    def self.new_from_savon(savon_response)
      new(
        code: savon_response.http.code,
        headers: savon_response.http.headers,
        body: savon_response.body
      )
    end

    def success(success_code = nil, match = false, &block)
      state_handling(:success, '2', success_code, match, &block)
    end

    def redirect(redirect_code = nil, match = false, &block)
      state_handling(:redirect, '3', redirect_code, match, &block)
    end

    def error(error_code = nil, match = false, &block)
      state_handling(:error, %w[4 5], error_code, match, &block)
    end

    def client_error(error_code = nil, match = false, &block)
      state_handling(:client_error, '4', error_code, match, &block)
    end

    def server_error(error_code = nil, match = false, &block)
      state_handling(:server_error, '5', error_code, match, &block)
    end

    def state=(signal)
      @state = @state_code || signal
    end

    private

    def state_handling(signal, http_codes, code = nil, must_match_code = false)
      if block_given?
        if code_match?(@code, http_codes)
          result = yield
          self.state = signal.to_sym
          @result = result || @state
        end
      else
        unless must_match_code && !code_match?(@code, http_codes)
          @state_code = [signal, code].compact.join('_').to_sym
          self.state = signal.to_sym
        end
      end
    end

    def code_match?(code, http_codes)
      return http_codes.include?(code.to_s.first) if http_codes.is_a? Array
      http_codes.to_s == code.to_s.first
    end
  end
end
