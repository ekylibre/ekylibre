require 'test_helper'

module FEC
  module Exporter
    class CSVTest < ActiveSupport::TestCase
      test 'build' do
        fy = JournalEntryItem.last.financial_year
        exporter = FEC::Exporter::CSV.new(fy, nil, fy.started_on, fy.stopped_on)
        assert exporter.write('tmp/fec.csv')
      end
    end
  end
end
