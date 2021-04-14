# frozen_string_literal: true

require 'test_helper'

module Interventions
  module Phytosanitary
    class PfiClientApiTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
      setup do
        @campaign = Campaign.find_or_create_by(name: '2020', harvest_year: 2020)
        # vitis
        @activity = Activity.find(6)
        # plant medicine Microthiol 6.4745 kg sp disp in spraying intervention
        @input = InterventionInput.find(100)
      end

      test 'API call return nil when no mandatory parameters is set' do
        c = Interventions::Phytosanitary::PfiClientApi.new(campaign: @campaign, activity: @activity, intervention_parameter_input: @input)
        response = c.compute_pfi
        assert_equal nil, response
      end
    end
  end
end
