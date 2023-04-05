require 'test_helper'

module Rides
  class ComputeWorkingZoneTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
    test 'It computes the right working zone' do
      crumb1 = create(:crumb, geolocation: Charta.new_point(0.82, 45.66))
      crumb2 = create(:crumb, geolocation: Charta.new_point(0.81, 45.66))
      line = Charta.make_line([crumb1.geolocation, crumb2.geolocation])
      ride = create(:ride)
      ride.crumbs << crumb1
      ride.crumbs << crumb2

      working_zone = Rides::ComputeWorkingZone.call(rides: [ride])
      assert_equal(4470.75047466861, working_zone.area)

      ride.ride_set.products.first.read!('width', Measure.new(10, :meter))
      working_zone = Rides::ComputeWorkingZone.call(rides: [ride])
      assert_equal(4470.75047466861, working_zone.area)
    end
  end
end
