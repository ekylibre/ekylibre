require 'test_helper'

class ProcedoTest < ActiveSupport::TestCase
  setup do
    I18n.locale = ENV['LOCALE']
  end

  test 'procedure methods' do
    procedure = Procedo::Procedure.new(:say_hello)
    procedure.add_parameter(:speaker, :doer, cardinality: 1)
    group = procedure.add_parameter_group(:home)
    group.add_parameter(:human, :tool)
    group.add_parameter(:dog, :tool)
    assert procedure.find(:speaker)
    assert procedure.find(:dog)
    assert procedure.find(:home)
  end

  test 'procedure parameter filters' do
    invalids = []
    Procedo.each_parameter do |parameter|
      begin
        WorkingSet.parse(parameter.filter) unless parameter.filter.nil?
      rescue WorkingSet::SyntaxError => e
        invalids << { parameter: parameter, exception: e }
      rescue WorkingSet::InvalidExpression => e
        invalids << { parameter: parameter, exception: e }
      end
    end

    details = invalids.map do |invalid|
      parameter = invalid[:parameter]
      exception = invalid[:exception]
      "#{parameter.name.to_s.yellow} in #{parameter.procedure.name.to_s.red}:\n" \
      "  expression: #{parameter.abilities.inspect}\n" \
      "  exception: #{exception.message}"
    end.join("\n")

    assert invalids.empty?, "#{invalids.count} procedure parameters have invalid abilities:\n" + details.dig
  end
end
