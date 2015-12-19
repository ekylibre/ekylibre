module Procedo
  class Cardinality
    attr_accessor :minimum, :maximum

    def initialize(object)
      @minimum = 0
      @maximum = +Float::INFINITY
      if object.is_a?(Cardinality)
        @minimum = object.minimum
        @maximum = object.maximum
      elsif object.is_a?(String)
        if object == '+'
          @minimum = 1
        elsif object == '?'
          @maximum = 1
        elsif object =~ /\A(\d+)?\.\.(\d+)?\z/
          array = object.split('..').map(&:strip)
          @minimum = array.first.to_i unless array.first.blank?
          @maximum = array.second.to_i unless array.second.blank?
        elsif object =~ /\A\d+\z/
          @minimum = @maximum = object.to_i
        elsif object != '*'
          fail "Cannot parse that: #{object.inspect}"
        end
      elsif object.is_a?(Numeric)
        @maximum = @minimum = object.to_i
      elsif object.is_a?(Range)
        @minimum = array.min
        @maximum = array.max
      else
        fail "Cannot handle that: #{object.inspect}"
      end
    end

    # Returns true if number is in the range, false otherwise.
    def include?(number)
      @minimum <= number && number <= @maximum
    end
  end
end
