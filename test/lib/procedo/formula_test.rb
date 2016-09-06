require 'test_helper'
require 'procedo'

module Procedo
  class FormulaTest < ActiveSupport::TestCase
    setup do
      I18n.locale = ENV['LOCALE']
    end

    test 'valid expressions' do
      invalids = []

      [
        # computed string expressions
        "'is %{variety_of(PRODUCT)}'",
        "'is %{variety_of(PRODUCT)} and derives from %{variant_of(PRODUCT)} and can %{DO}'",
        "'%{PRODUCT}%{VARIANT}%{NAME}'",
        "'is animal_group'",
        # indicators
        'PRODUCT.shape',
        'PRODUCT..thousand_grains_mass(gram)',
        # direct function call
        'variety_of(PRODUCT)'
      ].each do |expression|
        begin
          Procedo::Formula.parse(expression)
        rescue ::Procedo::Formula::SyntaxError => e
          invalids << { expression: expression, exception: e }
        end
      end

      details = invalids.map do |invalid|
        "#{invalid[:expression].inspect.yellow}: #{invalid[:exception].message}"
      end.join("\n")

      assert invalids.empty?, "#{invalids.count} formulas have invalid syntax:\n" + details.dig
    end

    test 'invalid expressions' do
      invalids = []

      [
        "'is %{'",
        "'%{}%{}%{}'",
        'PRODUCT.shape()',
        'PRODUCT..',
        'variety_of('
      ].each do |expression|
        assert_raise ::Procedo::Formula::SyntaxError, "An expression #{expression.inspect} should fail" do
          Procedo::Formula.parse(expression)
        end
      end

      details = invalids.map do |invalid|
        "#{invalid[:expression].inspect.yellow}: #{invalid[:exception].message}"
      end.join("\n")

      assert invalids.empty?, "#{invalids.count} formulas have invalid syntax:\n" + details.dig
    end
  end
end
