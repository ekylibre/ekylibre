require 'test_helper'

module Backend
  class LandParcelsHelperTest < ActionView::TestCase
    class Bidule
      include Backend::LandParcelsHelper
      def backend_visualizations_land_parcels_visualizations_path
        ''
      end

      def visualization(_blah, _osef)
        v = Object.new
        def v.control(_truc) end

        def v.center(_bidule) end

        yield v
      end
    end

    setup do
      @b = Bidule.new
    end

    test 'LandParcelsHelper::land_parcels_map does not fails when no LandParcel present' do
      LandParcel.delete_all

      assert_nothing_raised do
        @b.land_parcels_map
      end
    end
  end
end
