# encoding: UTF-8
require 'test_helper'

class AggeratioTest < ActiveSupport::TestCase

  setup do
    @controller = Backend::ExportsController.new
    # animal_husbandry_registry
    ProductNature.import_from_nomenclature :animal_building_division
  end

  Aggeratio.each do |klass|

    test "aggregator #{klass.aggregator_name}" do
      assert klass < Aggeratio::Aggregator, "Aggregator #{klass.inspect} must be a child of Aggeratio::Aggregator"
      params = {}

      aggregator = klass.new(params)

      aggregator.to_xml

      aggregator.to_html_fragment
    end

  end

end
