module ActiveExchanger
  class Result
    class << self
      private :new

      def success
        new(:success)
      end

      def aborted(message = nil, exception: nil)
        new(:aborted, message: message, exception: exception)
      end

      def failed(message = nil, exception: nil)
        new(:failed, message: message, exception: exception)
      end
    end

    attr_reader :state, :message, :exception

    def initialize(state, message: nil, exception: nil)
      @state = state
      if message.nil? && exception.present?
        message = exception.message
      end
      @message = message
      @exception = exception
    end

    def success?
      state === :success
    end

    alias_method :to_bool, :success?

    def error?
      !success?
    end

    def raise_if_error!
      return if success?
      if @exception.present?
        raise @exception
      else
        raise ActiveExchanger::Error, @message
      end
    end

  end
end
