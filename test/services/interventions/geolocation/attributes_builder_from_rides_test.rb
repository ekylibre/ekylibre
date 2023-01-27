require 'test_helper'

module Interventions
  module Geolocation
    class AttributesBuilderFromRidesTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
      setup do
        @activity = Activity.find_by(production_cycle: :perennial, family: 'vine_farming')
        @campaign = Campaign.of(2022)
        @ride_shape_inside_zc = Charta.new_geometry('LINESTRING (-0.796765776844419 45.8241705877912, -0.796686844980288 45.8241935063968, -0.797318299893339 45.8251423283857, -0.79796291011708 45.8261278027025, -0.797930021840358 45.8262515587093, -0.798015531359834 45.8261965560736, -0.797890555908292 45.8261415533835, -0.797134125543699 45.8249681497156, -0.796640801392878 45.824221008711, -0.796509248285992 45.8241751715131, -0.796528981252025 45.824230176146, -0.796621068426845 45.8241705877912, -0.796555291873402 45.8242622621568, -0.797397231757471 45.8255365202059, -0.797818201699505 45.8261736382927, -0.797778735767439 45.8262882271029, -0.797883978252948 45.8262790600067, -0.797785313422784 45.8262057231833, -0.797752425146062 45.8262103067376, -0.796693422635632 45.8246197907403, -0.796482937664615 45.8242805970118)')
        # like ZC07 shape - Bois granger
        @plant_shape = Charta.new_geometry('MULTIPOLYGON (((-0.794615923168251 45.8245110615351, -0.796745301297287 45.8241278199603, -0.7969981861949 45.8244993802596, -0.797381791778223 45.8251189620263, -0.797725959291237 45.8255147119002, -0.798005296749384 45.82588446069, -0.79807126407617 45.8261353553017, -0.797969241518434 45.8263899559536, -0.797762044670599 45.8265844564199, -0.797307204069654 45.8267591250923, -0.796860387303264 45.8268169716943, -0.796756719854117 45.8268105874591, -0.796646985685123 45.826462942571, -0.796658061475265 45.8262191740923, -0.796477774844415 45.8257476158095, -0.795355047350702 45.8259315435604, -0.794615923168251 45.8245110615351)))')
        @cultivable_zone = CultivableZone.create!(name: "IG plant", shape: @plant_shape)
      end

      test 'Return the right attributes if ride is not linkable and crop doesn\'t match' do
        ride = create(:ride, nature: :road)
        attributes = AttributesBuilderFromRides.call(ride_ids: [ride.id], procedure_name: 'vine_raking' )
        assert_equal([], attributes[:ride_ids])
        assert_equal([], attributes[:group_parameters_attributes])
        assert_equal([], attributes[:targets_attributes])
      end

      test 'Return the right attributes if ride is assigneable and crop matches' do
        started_at = DateTime.new(2022, 6, 1)
        stopped_at = DateTime.new(2022, 6, 2)
        ride = create(:ride, nature: :work, intervention_id: nil, started_at: started_at, stopped_at: stopped_at, shape: @ride_shape_inside_zc)
        plant = create(:plant,
                       initial_shape: @plant_shape,
                       born_at: started_at - 1.day)
        activity_production = create(:activity_production, campaign: @campaign, activity: @activity, cultivable_zone: @cultivable_zone, started_on: started_at.to_date, support: plant)
        plant.reload

        attributes = AttributesBuilderFromRides.call(ride_ids: [ride.id], procedure_name: 'vine_raking', target_class: Plant )
        assert_equal(ride.id, attributes[:ride_ids].first)
        assert_equal(:cultivation, attributes[:targets_attributes].first[:reference_name])
        assert_equal(plant.id, attributes[:targets_attributes].first[:product_id])
        assert(attributes[:targets_attributes].first[:working_zone])

        assert_equal({ started_at: started_at, stopped_at: stopped_at }, attributes[:working_periods_attributes].first)
      end
    end
  end
end
