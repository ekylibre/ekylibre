require 'test_helper'

module Interventions
  module Phytosanitary
    class PhytoHarvestAdvisorTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
      setup do
        @harvest_period = Models::Period.parse("2013-09-16T05:00:25+00:00", "2013-09-16T17:00:25+00:00")

        @target = create(:corn_plant)

        @spraying_intervention = create :intervention, :spraying, :with_target,
                                        on: @target,
                                        started_at: "2020-02-26T12:00:25+00:00",
                                        stopped_at: "2020-02-26T14:00:25+00:00"
      end

      test 'compute result not possible' do
        periods = [
          ["2013-09-16T04:00:25+00:00", "2013-09-16T17:30:25+00:00"],
          ["2013-09-16T04:00:25+00:00", "2013-09-16T15:30:25+00:00"],
          ["2013-09-16T13:30:25+00:00", "2013-09-16T15:30:25+00:00"],
          ["2013-09-16T16:10:25+00:00", "2013-09-16T17:25:25+00:00"],
          ["2013-09-16T17:10:25+00:00", "2013-09-16T18:35:25+00:00"],
          ["2013-09-16T03:00:25+00:00", "2013-09-16T04:30:25+00:00"]
        ]

        pulve_periods = periods.map { |start_date, end_date| Models::Period.parse(start_date, end_date) }
        results = PhytoHarvestAdvisor.new.compute_result(@harvest_period, pulve_periods)

        assert_not results.possible
        assert_equal DateTime.soft_parse("2013-09-16T17:30:25+00:00"), results.next_possible_date
      end

      test 'compute result possible' do
        periods = [
          ["2013-09-16T02:00:25+00:00", "2013-09-16T02:30:25+00:00"],
          ["2013-09-16T17:30:25+00:00", "2013-09-16T19:30:25+00:00"]
        ]

        pulve_periods = periods.map { |start_date, end_date| Models::Period.parse(start_date, end_date) }
        results = PhytoHarvestAdvisor.new.compute_result(@harvest_period, pulve_periods)

        assert results.possible
      end

      test 'get product id from target' do
        assert_equal [@target.id, @target.production.support_id], PhytoHarvestAdvisor.new.get_product_id_from_target(@target)
      end

      test 'get interventions from target' do
        assert_empty PhytoHarvestAdvisor.new.get_interventions_from_target(@target, @spraying_intervention)
        assert_equal [@spraying_intervention], PhytoHarvestAdvisor.new.get_interventions_from_target(@target, nil)
      end

      test 'reentry possible from interventions?' do
        harvest_period = Models::Period.parse("2020-02-26T14:05:25+00:00", "2020-02-26T17:00:25+00:00")

        reentry_delay = PhytoHarvestAdvisor.new.reentry_possible_from_interventions?(harvest_period, [@spraying_intervention])

        assert_equal DateTime.soft_parse("2020-02-26T20:00:25+00:00"), reentry_delay.next_possible_date
        assert_equal 8.hours, reentry_delay.period_duration
        assert_not reentry_delay.possible
      end

      test 'harvest not possible from interventions' do
        harvest_period = Models::Period.parse("2020-02-26T14:05:25+00:00", "2020-02-26T17:00:25+00:00")
        pre_harvest_delay = PhytoHarvestAdvisor.new.harvest_possible_from_interventions?(harvest_period, [@spraying_intervention])

        assert_equal DateTime.soft_parse("2020-02-29T14:00:25+00:00"), pre_harvest_delay.next_possible_date
        assert_not pre_harvest_delay.possible
      end

      test 'harvest possible from interventions' do
        harvest_period = Models::Period.parse("2020-02-29T14:05:25+00:00", "2020-02-29T17:00:25+00:00")
        pre_harvest_delay = PhytoHarvestAdvisor.new.harvest_possible_from_interventions?(harvest_period, interventions)

        assert pre_harvest_delay.possible
      end
    end
  end
end
