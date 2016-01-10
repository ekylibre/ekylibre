module Procedo
  class Procedure
    # An Attribute defines an information to complete
    class Field
      attr_reader :name, :parameter

      delegate :procedure, to: :parameter
      delegate :name, to: :parameter, prefix: true
      delegate :name, to: :procedure, prefix: true

      def initialize(parameter, name, options = {})
        @parameter = parameter
        self.name = name
        @options = options
      end

      # Sets the name
      def name=(value)
        @name = value.to_sym
      end
    end
  end
end
