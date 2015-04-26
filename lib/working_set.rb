module WorkingSet

  autoload :AbilityArray,  'working_set/ability_array'
  autoload :QueryLanguage, 'working_set/query_language'
  autoload :SQLCompiler,   'working_set/sql_compiler'

  class Parser < Treetop::Runtime::CompiledParser
    include QueryLanguage
  end

  class SyntaxError < StandardError
  end

  module QueryLanguage
    class Base < Treetop::Runtime::SyntaxNode; end
    class BooleanExpression           < Base              ; end
    class BooleanOperation            < Base              ; end
    class Conjunction                 < BooleanOperation  ; end
    class Disjunction                 < BooleanOperation  ; end
    class Test                        < Base              ; end # Abstract
    class NegativeTest                < Test              ; end
    class AbilityTest                 < Test              ; end
    class EssenceTest                 < Test              ; end
    class DerivativeTest              < Test              ; end
    class IndicatorTest               < Test              ; end
    class AbilityName                 < Base              ; end
    class AbilityArgument             < Base              ; end
    class VarietyName                 < Base              ; end
  end

  class << self

    def parse(expression, options = {})
      @parser ||= ::WorkingSet::Parser.new
      unless tree = @parser.parse(expression.to_s, options)
        raise SyntaxError, @parser.failure_reason + "\nExpression: " + expression.inspect
      end
      return tree
    end

    def to_sql(expression, options = {})
      tree = parse(expression)
      ::WorkingSet::SQLCompiler.new(tree).compile(options)
    end

  end
end
