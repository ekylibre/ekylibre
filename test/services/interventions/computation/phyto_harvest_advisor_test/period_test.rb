require 'test_helper'

module Interventions
  module Computation
    module PhytoHarvestAdvisorTest
      class PeriodTest < Ekylibre::Testing::ApplicationTestCase
        setup do
          @p = PhytoHarvestAdvisor::Period.new("2019-01-12T15:30:25+01:00", "2019-01-12T16:30:25+01:00")
        end

        test 'intersect periods' do
          cases = [
            ["2019-01-12T13:30:25+01:00", "2019-01-12T14:30:25+01:00", false],
            ["2019-01-12T13:30:25+01:00", "2019-01-12T17:30:25+01:00", true],
            ["2019-01-12T13:30:25+01:00", "2019-01-12T16:00:25+01:00", true],
            ["2019-01-12T15:35:25+01:00", "2019-01-12T16:00:25+01:00", true],
            ["2019-01-12T16:00:25+01:00", "2019-01-12T17:30:25+01:00", true],
            ["2019-01-12T17:30:25+01:00", "2019-01-12T18:30:25+01:00", false]
          ]

          cases.each do |(start, stop, expected)|
            assert_equal expected, @p.intersect?(PhytoHarvestAdvisor::Period.new(start, stop))
          end
        end
      end
    end
  end
end
