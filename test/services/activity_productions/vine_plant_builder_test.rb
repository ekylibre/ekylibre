require 'test_helper'

module ActivityProductions
  # Build vine plant from activity_production
  class VinePlantBuilderTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
    setup do
      @campaign = create(:campaign, harvest_year: 2018)
      @production = activity_productions(:activity_productions_045)
    end

    attr_reader :campaign, :production

    test 'return plant on first call and message on second' do
      plant_creation_service = ActivityProductions::VinePlantBuilder.new(production, campaign)
      plant = plant_creation_service.create_vine_plant_from_production
      assert plant
      assert_equal plant.initial_shape, production.support_shape
      assert_equal plant.initial_born_at.to_date, Date.new(campaign.harvest_year, 1, 1)
      plant = plant_creation_service.create_vine_plant_from_production
      assert_equal plant, 'Plant already exist for this activity production'
    end

  end
end
