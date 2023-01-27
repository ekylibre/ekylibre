require 'test_helper'

module Interventions
  module Geolocation
    class SimilaritiesWithRidesScoreCounterTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
      setup do
        @intervention = create(:intervention)
        ride_list = create_list(:ride, 2, started_at: Date.new(2018, 0o1, 0o1), stopped_at: Date.new(2018, 0o1, 0o1) + 1.hour)
        @rides = Ride.where(id: ride_list.map(&:id))
      end

      test '#date_score Count is 0 if the date is the same' do
        rides = create_list(:ride, 2, started_at: Date.new(2018, 0o1, 0o1), stopped_at: Date.new(2018, 0o1, 0o1) + 1.hour)
        count = SimilaritiesWithRidesScoreCounter
          .new(intervention: @intervention, rides: @rides)
          .date_score
        assert_equal(0, count)
      end

      test '#date_score Count : is n the date is n times superior to ride date' do
        rides = create_list(:ride, 2, started_at: Date.new(2018, 0o1, 0o3), stopped_at: Date.new(2018, 0o1, 0o3) + 1.hour)
        count = SimilaritiesWithRidesScoreCounter
          .new(intervention: @intervention, rides: rides)
          .date_score
        assert_equal(-2, count)
      end

      test '#equipment_score : Count is 1 if they both use the same equipment' do
        tractor = create(:tractor)
        @rides.each{ |r| r.update( product_id: tractor.id )}
        @intervention.tools << create(:intervention_tool, product_id: tractor.id)
        count = SimilaritiesWithRidesScoreCounter
          .new(intervention: @intervention, rides: @rides)
          .equipment_score
        assert_equal(1, count)
      end

      test '#localization_score : Count is 1 if targets & rides share the same cultivable zone' do
        target =  create(:intervention_target)
        activity_production = create(:corn_activity_production, :with_cultivable_zone)
        product = target.product
        product.activity_production = activity_production
        product.save
        cultivable_zone = product.activity_production.cultivable_zone
        @intervention.targets << target
        @rides.map {|ride| ride.update(cultivable_zone_id: cultivable_zone.id) }
        count = SimilaritiesWithRidesScoreCounter
          .new(intervention: @intervention, rides: @rides)
          .localization_score
        assert_equal(1, count)
      end

    end
  end
end
