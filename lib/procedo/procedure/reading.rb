module Procedo
  class Procedure
    # An Attribute defines an information to complete
    class Reading < Procedo::Procedure::Field
      def initialize(parameter, name, options = {})
        super(parameter, name, options)
        Nomen::Indicator.find!(@name)
      end
    end
  end
end
