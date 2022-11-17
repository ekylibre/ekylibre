require 'test_helper'

module Interventions
  module Geolocation
    class AttributesBuilderFromRidesTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
      setup do
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
        ride = create(:ride, nature: :work, intervention_id: nil, started_at: started_at, stopped_at: stopped_at)
        plant = create(:plant,
                       initial_shape: Charta.new_geometry('POLYGON((-0.8211432242422689 45.66115527071159,-0.8195660853415121 45.66115527071159,-0.8195660853415121 45.660195468924435,-0.8211432242422689 45.660195468924435,-0.8211432242422689 45.66115527071159))'),
                       born_at: started_at - 1.day)
        working_zone = Charta.new_geometry('POLYGON ((-0.8197551518883535 45.66029812293619, -0.8197513168081579 45.66028291906724, -0.8197654633310074 45.66027879734437, -0.82094563529756 45.6610061473144, -0.8209494703777558 45.661021351377165, -0.8209353238549062 45.661025473153984, -0.8197551518883535 45.66029812293619))')
        w_zone_computation_mock = Minitest::Mock.new
        w_zone_computation_mock.expect(:call, working_zone, [{ rides: [ride] }])

        Rides::ComputeWorkingZone.stub :call, w_zone_computation_mock do
          attributes = AttributesBuilderFromRides.call(ride_ids: [ride.id], procedure_name: 'vine_raking', target_class: Plant )
          assert_equal(ride.id, attributes[:ride_ids].first)
          assert_equal(:cultivation, attributes[:targets_attributes].first[:reference_name])
          assert_equal(plant.id, attributes[:targets_attributes].first[:product_id])
          assert(attributes[:targets_attributes].first[:working_zone])

          assert_equal({ started_at: started_at, stopped_at: stopped_at }, attributes[:working_periods_attributes].first)
        end
        w_zone_computation_mock.verify
      end
    end
  end
end
