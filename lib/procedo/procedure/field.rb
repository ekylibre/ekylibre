# coding: utf-8

module Procedo
  class Procedure
    # An Attribute defines an information to complete
    class Field
      include Codeable

      delegate :procedure, to: :parameter
      delegate :name, to: :parameter, prefix: true
      delegate :name, to: :procedure, prefix: true

      attr_reader :name, :parameter

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
