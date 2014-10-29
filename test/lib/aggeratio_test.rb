# encoding: UTF-8
require 'test_helper'

class AggeratioTest < ActiveSupport::TestCase

  setup do
    DocumentTemplate.load_defaults
    @parameters = {
      exchange_accountancy_file_fr: {started_on: "2007-01-01", stopped_on: "2007-12-31"}.with_indifferent_access
    }.with_indifferent_access
  end


  Aggeratio.each_xml_aggregator do |element|

    agg = Aggeratio::Base.new(element)
    klass = "Aggeratio::#{agg.class_name}".constantize

    test "aggregator #{klass.aggregator_name} exports" do
      aggregator = klass.new(@parameters[klass.aggregator_name])

      assert klass < Aggeratio::Aggregator, "Aggregator #{klass.inspect} must be a child of Aggeratio::Aggregator"

      # Test HTML export
      aggregator.to_html_fragment

      # Test XML export
      xml = aggregator.to_xml

      # Test PDF export
      if Nomen::DocumentNatures[klass.aggregator_name]
        DocumentTemplate.where(nature: klass.aggregator_name).each do |template|
          template.export(xml, rand(999_999).to_s(36), :pdf)
        end
      end

      # Check that test data are complete to use all item of aggregators
      doc = Nokogiri::XML(xml, nil, nil, Nokogiri::XML::ParseOptions::NOBLANKS|Nokogiri::XML::ParseOptions::STRICT|Nokogiri::XML::ParseOptions::DEFAULT_XML)
      errors, queries = [], agg.queries
      queries.each do |query|
        errors << query unless doc.xpath(query).size > 0
      end
      assert errors.empty?, "Cannot find #{errors.count} elements in XML export (among #{queries.count}). Fixtures may be incomplete.\nMissing element are:\n" + errors.join("\n").dig # + "\nXML:\n" + xml.dig
    end

  end

end
