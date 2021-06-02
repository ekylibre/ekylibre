require 'test_helper'

module ActivityProductions
  # Build activity production default values
  class DefaultAttributesValueBuilderTest < Ekylibre::Testing::ApplicationTestCase
    setup do
      @campaign = create(:campaign, harvest_year: 2011)
    end

    attr_reader :campaign

    test 'return correct attributes if perennial' do
      activity = create(:activity,
                        production_cycle: :perennial,
                        start_state_of_production_year: 3,
                        production_started_on: Date.new(2000, 1, 1),
                        production_stopped_on: Date.new(2000, 2, 2),
                        production_started_on_year: -1,
                        production_stopped_on_year:  0,
                        life_duration: 30)
      attributes = DefaultAttributesValueBuilder.build(activity, campaign)
      assert_equal Date.new(2010, 1, 1), attributes.fetch(:started_on)
      assert_equal Date.new(2040, 2, 2), attributes.fetch(:stopped_on)
      assert_equal 2013, attributes.fetch(:starting_year)
    end

    test 'return correct attributes if activity is annual and the cycle is setted' do
      activity = create(:activity,
                        production_started_on: Date.new(2000, 1, 1),
                        production_stopped_on: Date.new(2000, 2, 2),
                        production_started_on_year: -1,
                        production_stopped_on_year:  1)
      attributes = DefaultAttributesValueBuilder.build(activity, campaign)
      assert_equal Date.new(2010, 1, 1), attributes.fetch(:started_on)
      assert_equal Date.new(2012, 2, 2), attributes.fetch(:stopped_on)
      assert_equal nil, attributes.fetch(:starting_year)
    end

    test 'return correct attributes if activity is annual and the cycle is not setted' do
      activity = create(:activity,
                        production_started_on: nil,
                        production_stopped_on: nil,
                        production_started_on_year: nil,
                        production_stopped_on_year: nil)
      attributes = DefaultAttributesValueBuilder.build(activity, campaign)
      assert_equal Date.today.change(year: 2011), attributes.fetch(:started_on)
      assert_equal (Date.today - 1.day).change(year: 2012), attributes.fetch(:stopped_on)
      assert_equal nil, attributes.fetch(:starting_year)
    end

  end
end
