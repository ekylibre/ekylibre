require 'test_helper'

module FEC
  module Exporter
    class XMLTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
      test 'build' do
        fy = JournalEntryItem.last.financial_year
        exporter = FEC::Exporter::XML.new(fy, nil, fy.started_on, fy.stopped_on)
        assert exporter.write('tmp/fec.xml')
      end
    end
  end
end
