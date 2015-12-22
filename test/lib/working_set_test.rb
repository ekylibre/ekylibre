require 'test_helper'

class WorkingSetsTest < ActiveSupport::TestCase
  test 'valid expressions' do
    invalids = []
    [
      'is aix',
      'is   sus',
      'isnt sus_scrofa',
      'derives from mammalia',
      'derives   from   immatter',
      'dont derive   from   immatter',
      'dont   derive   from   immatter',
      'dont derive from equidae',
      'has indicator net_mass',
      'has frozen indicator net_volume',
      'has variable indicator net_mass',
      'can grow',
      'can grow()',
      'can treat(diarrhea, bison)',
      'can consume(water)',
      'can consume(water) and is bos',
      'can consume(water) and (is bos or is felidae)'
    ].each do |expression|
      done = false
      begin
        sql = WorkingSet.to_sql(expression)
        done = true
        ProductNature.where(sql).count
      rescue WorkingSet::SyntaxError => e
        invalids << { expression: expression, exception: e }
      end
    end

    details = invalids.map do |invalid|
      "#{invalid[:expression].inspect.yellow}: #{invalid[:exception].message}"
    end.join("\n")

    assert invalids.empty?, "#{invalids.count} working sets have invalid syntax:\n" + details.dig
  end

  test 'invalid expressions' do
    invalids = []
    [
      'is not aix',
      'isnot aix',
      '  is aix',
      ' is aix ',
      'is aix  ',
      'dont derives from mammalia',
      'hasnt indicator net_mass',
      'hasnot frozen indicator net_volume',
      'has not variable indicator net_mass',
      'cannot treat(diarrhea, bison)',
      'can not consume(water)',
      'can consume(water) and is bos or bison'
    ].each do |expression|
      done = false
      assert_raise WorkingSet::SyntaxError, "An expression #{expression.inspect} should fail" do
        WorkingSet.to_sql(expression)
      end
    end
  end
end
