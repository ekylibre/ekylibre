module Tele::Idele::Errors
  module ExceptionNormalization
    module Initializer
      attr_reader :code, :message

      def initialize(options = {})
        @code = options[:code]
        @message = options[:message]
        log = ''

        log = @code + ': ' unless @code.nil?

        log += @message unless @message.nil?

        Rails.logger.warn log
        super @message
      end
    end

    def self.included(klass)
      klass.send :prepend, Initializer
    end
  end

  class ParsingError < StandardError
    include ExceptionNormalization
  end

  class SOAPError < Savon::Error
    include ExceptionNormalization
  end

  class CurlError < Curl::Err::CurlError
    include ExceptionNormalization
  end

  class NokogiriError < Nokogiri::XML::SyntaxError
    include ExceptionNormalization
  end
end
