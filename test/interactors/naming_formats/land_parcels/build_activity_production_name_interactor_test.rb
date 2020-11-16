require 'test_helper'

module NamingFormats
  module LandParcels
    class BuildActivityProductionNameInteractorTest < Ekylibre::Testing::ApplicationTestCase
      setup do
        @activity_production = create(:activity_production, :with_cultivable_zone)
        @naming_format = NamingFormatLandParcel.load_defaults
      end

      test 'generate the right name with default naming_format ' do
        expected_name = [@activity_production.cultivable_zone.name,
                         @activity_production.activity.name,
                         @activity_production.campaign.name,
                         @activity_production.custom_name,
                         "##{@activity_production.rank_number}"].join(' ')
        interactor = NamingFormats::LandParcels::BuildActivityProductionNameInteractor.call(activity_production: @activity_production)
        assert_equal expected_name, interactor.build_name
      end
    end
  end
end
