module Procedo
  module Formula
    module Nodes
      class Base < Treetop::Runtime::SyntaxNode; end
      class Expression < Base; end
      class StringExpression < Base; end
      class Text < Base; end
      class Interpolation < Base; end
      class Condition < Base; end
      class Operation < Base; end # Abstract
      class Multiplication < Operation; end
      class Division < Operation; end
      class Addition < Operation; end
      class Substraction < Operation; end
      class BooleanExpression < Base; end
      class BooleanOperation < Base; end
      class Conjunction < BooleanOperation; end
      class Disjunction < BooleanOperation; end
      class ExclusiveDisjunction < BooleanOperation; end
      class Test < Base; end # Abstract
      class Comparison < Test; end # Abstract
      class StrictSuperiorityComparison < Comparison; end
      class StrictInferiortyComparison < Comparison; end
      class SuperiorityComparison < Comparison; end
      class InferiorityComparison < Comparison; end
      class EqualityComparison < Comparison; end
      class DifferenceComparison < Comparison; end
      class PresenceTest < Test; end
      class ActorPresenceTest < PresenceTest; end
      class IndicatorPresenceTest < PresenceTest; end
      class IndividualIndicatorPresenceTest < PresenceTest; end
      class VariablePresenceTest < PresenceTest; end
      class NegativeTest < Test; end
      class Reading < Base; end # Abstract
      class IndividualReading < Reading; end
      class WholeReading < Reading; end
      class FunctionCall < Base; end
      class FunctionName < Base; end
      class EnvironmentVariable < Base; end
      class Variable < Base; end
      class Indicator < Base; end
      class Unit < Base; end
      class Numeric < Base; end
      class Symbol < Base; end
    end
  end
end
