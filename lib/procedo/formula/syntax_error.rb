module Procedo
  module Formula
    class SyntaxError < StandardError
      attr_reader :parser
      delegate :failure_index, :failure_column, :failure_line, to: :parser
      def initialize(parser)
        @parser = parser
        super(@parser.failure_reason)
      end
    end
  end
end
