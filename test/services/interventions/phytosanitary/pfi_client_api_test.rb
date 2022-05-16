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
        @client = Interventions::Phytosanitary::PfiClientApi.new(campaign: @campaign, activity: @activity, intervention_parameter_input: @input, notify_user: true)

        VCR.configure do |config|
          config.cassette_library_dir = 'test/cassettes/pfi_client'
          config.default_cassette_options = {
            serialize_with: :yaml,
            record: :once,
            allow_playback_repeats: true,
            decode_compressed_response: true
          }
        end
      end

      attr_reader :client, :input, :activity, :campaign

      test '#down? return false if service is up' do
        VCR.use_cassette('up') do
          refute(client.down?)
        end
      end

      test '#down? return true if service is down' do
        VCR.use_cassette('down') do
          assert(client.down?)
        end
      end

      test '#get_campaign with not existing campaign' do
        VCR.use_cassette('unexisting_campaign') do
          assert_nil(client.get_campaign('2030'), "Return nil if campaign doesn't exist" )
          assert_difference ->{ input.intervention.creator.notifications.count }, 1, 'Send error notification to the intervention creator' do
            client.get_campaign('2030')
          end
        end
      end

      test '#get_campaign with existing campaign' do
        VCR.use_cassette('existing_campaign') do
          response = client.get_campaign('2020')
          assert(200, response.code)
        end
      end

      test '#compute_pfi when mandatory parameters are not set' do
        activity.update(reference_name: nil)
        client = Interventions::Phytosanitary::PfiClientApi.new(campaign: campaign, activity: activity, intervention_parameter_input: input, notify_user: true)
        VCR.use_cassette('compute_pfi_with_missing_parameter') do
          assert_nil client.compute_pfi
        end
      end

      test '#compute_pfi when mandatory parameters are set' do
        user_notification_count = @input.intervention.creator.notifications.count
        VCR.use_cassette('compute_pfi_with_all_parameters') do
          response = client.compute_pfi
          assert_not_nil(response)
          assert_not_nil(response.dig(:iftTraitement, :ift))
          if response.dig(:iftTraitement, :avertissement)
            assert_equal(user_notification_count + 1, @input.intervention.creator.notifications.count, 'Send warning notification to the intervention creator' )
          end
          assert_not_nil(response.dig(:iftTraitement, :segment, :idMetier))
          assert_not_nil(response.dig(:signature))
        end
      end
    end
  end
end
