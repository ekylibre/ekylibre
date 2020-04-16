module Accountancy
  module ConditionBuilder
    class Base
      attr_reader :connection

      def initialize(connection:)
        @connection = connection
      end

      def quote(value)
        connection.quote(value)
      end
    end
  end
end