require 'test_helper'

module FEC
  module Exporter
    class XMLTest < ActiveSupport::TestCase
      test 'build' do
        fy = JournalEntryItem.last.financial_year
        exporter = FEC::Exporter::XML.new(fy)
        assert exporter.write('tmp/fec.xml')
      end
    end
  end
end
