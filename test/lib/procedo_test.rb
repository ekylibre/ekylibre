require 'test_helper'

class ProcedoTest < ActiveSupport::TestCase
  setup do
    I18n.locale = ENV['LOCALE']
  end

  test 'procedure variable abilities' do
    invalids = []
    Procedo.each_variable do |variable|
      begin
        variable.abilities.check!
      rescue WorkingSet::InvalidExpression => e
        invalids << { variable: variable, exception: e }
      end
    end

    details = invalids.map do |invalid|
      variable = invalid[:variable]
      exception = invalid[:exception]
      "#{variable.name.to_s.yellow} in #{variable.procedure.name.to_s.red}:\n" \
      "  expression: #{variable.abilities.inspect}\n" \
      "  exception: #{exception.message}"
    end.join("\n")

    assert invalids.empty?, "#{invalids.count} procedure variables have invalid abilities:\n" + details.dig
  end
end
