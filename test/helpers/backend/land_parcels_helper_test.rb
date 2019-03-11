require 'test_helper'

module Backend
  class LandParcelsHelperTest < ActionView::TestCase
    class MockLandParcelHelper
      include Backend::LandParcelsHelper
      def backend_visualizations_land_parcels_visualizations_path
        ''
      end

      def visualization(_param1, _param2)
        v = Object.new
        def v.control(_arg1) end

        def v.center(_arg2) end

        yield v
      end
    end

    setup do
      @helper = MockLandParcelHelper.new
    end

    test 'LandParcelsHelper::land_parcels_map does not fails when no LandParcel present' do
      LandParcel.delete_all

      assert_nothing_raised do
        @helper.land_parcels_map
      end
    end
  end
end
