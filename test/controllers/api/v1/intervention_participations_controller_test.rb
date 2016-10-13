require 'test_helper'
module Api
  module V1
    class InterventionParticipationsControllerTest < ActionController::TestCase
      connect_with_token

      test 'receiving an empty payload doesn\'t blow up' do
        add_auth_header

        assert_nothing_raised { post(:create, {}) }
      end

      test 'receiving an appropriate payload creates an appropriate InterventionParticipation and returns it id' do
        add_auth_header

        part_id = JSON(post(:create, correct_payload).body)['id']
        assert_not_nil part_id
        assert_not_nil part = InterventionParticipation.find_by(id: part_id)

        assert_equal true, part.request_compliant
        assert_equal 9, part.working_periods.count
        assert_equal :done, part.state.to_sym
      end

      test 'receiving a payload doesn\'t generate an InterventionParticipation if not needed' do
        add_auth_header

        part_id_una = JSON(post(:create, correct_payload).body)['id']
        part_id_bis = JSON(post(:create, correct_payload).body)['id']

        assert_equal part_id_una, part_id_bis
      end

      test 'handles completely wrong payload graciously' do
        add_auth_header

        assert_nothing_raised { post(:create, { yolo: :swag, test: [:bidouille, 'le malin', 1_543_545], 54 => 1_014_441 }) }
      end

      # This test can only work if the intervention being created really is unique yet.
      test 'instantiate an intervention if it doesn\'t exist' do
        add_auth_header

        # destroy_all to up our unicity chances
        to_destroy = Intervention.where.not(id: Intervention.where(nature: :record).first).reject(&:with_undestroyable_products?).map(&:id)
        Intervention.where(id: to_destroy).destroy_all
        diff_state = Intervention.first.done? ? :in_progress : :done # Ensures we have a non already-existent intervention.
        original_count = Intervention.where(nature: :record).count
        post(:create, correct_payload(state: diff_state))

        assert_equal original_count + 1, Intervention.where(nature: :record).count
      end

      test 'doesn\'t instantiate an intervention if a fitting one exists' do
        add_auth_header

        post(:create, body: correct_payload.to_json)
        original_count = Intervention.count

        post(:create, body: correct_payload.to_json)
        new_count = Intervention.count

        assert_equal original_count, new_count
      end

      test 'ignores working periods that already exist' do
        add_auth_header

        part_id = JSON(post(:create, repeating_payload).body)['id']
        original_count = InterventionParticipation.find(part_id).working_periods.count

        assert_equal 2, original_count

        part_id = JSON(post(:create, repeating_payload).body)['id']
        new_count = InterventionParticipation.find(part_id).working_periods.count

        assert_equal original_count, new_count
      end

      test 'ignores overlapping working periods' do
        add_auth_header

        part_id = JSON(post(:create, overlapping_payload).body)['id']
        original_count = InterventionParticipation.find(part_id).working_periods.count

        assert_equal 1, original_count

        part_id = JSON(post(:create, overlapping_payload(only_overlap: true)).body)['id']
        new_count = InterventionParticipation.find(part_id).working_periods.count

        assert_equal original_count, new_count
      end

      test 'created working_periods have the correct nature' do
        add_auth_header

        part_id = JSON(post(:create, correct_payload).body)['id']
        natures = InterventionParticipation.find(part_id).working_periods.order(:started_at).pluck(:nature).map(&:to_sym)

        assert_equal [:preparation, :travel, :intervention, :travel, :preparation, :travel, :intervention, :travel, :preparation], natures
      end

      private

      def correct_payload(state: :done, procedure: :plant_watering, action: :irrigation)
        request = Intervention.find_or_create_by!(nature: :request, procedure_name: procedure, actions: [action])
        {
          request_intervention_id: request.id,
          request_compliant: 1,
          uuid: '1d5fd107-7321-49d3-915f-88ab27599d9f',
          state: state.to_s,
          procedure_name: procedure.to_s,
          device_uid: 'android:dd60319e524d3d24',
          working_periods:
          [
            {
              started_at: '2016-09-30T11:59:49.320+0200',
              stopped_at: '2016-09-30T11:59:50.770+0200',
              nature:     'preparation'
            },
            {
              started_at: '2016-09-30T11:59:50.770+0200',
              stopped_at: '2016-09-30T11:59:51.836+0200',
              nature:     'travel'
            },
            {
              started_at: '2016-09-30T11:59:51.836+0200',
              stopped_at: '2016-09-30T11:59:52.620+0200',
              nature:     'intervention'
            },
            {
              started_at: '2016-09-30T11:59:52.620+0200',
              stopped_at: '2016-09-30T11:59:55.903+0200',
              nature:     'travel'
            },
            {
              started_at: '2016-09-30T11:59:55.903+0200',
              stopped_at: '2016-09-30T11:59:56.320+0200',
              nature:     'preparation'
            },
            {
              started_at: '2016-09-30T11:59:56.320+0200',
              stopped_at: '2016-09-30T11:59:56.669+0200',
              nature:     'travel'
            },
            {
              started_at: '2016-09-30T11:59:56.669+0200',
              stopped_at: '2016-09-30T11:59:56.969+0200',
              nature:     'intervention'
            },
            {
              started_at: '2016-09-30T11:59:56.969+0200',
              stopped_at: '2016-09-30T11:59:57.353+0200',
              nature:     'travel'
            },
            {
              started_at: '2016-09-30T11:59:57.353+0200',
              stopped_at: '2016-09-30T11:59:58.603+0200',
              nature:     'preparation'
            }
          ]
        }
      end

      def overlapping_payload(state: :done, procedure: :plant_watering, action: :irrigation, only_overlap: false)
        request = Intervention.create!(nature: :request, procedure_name: procedure, actions: [action])
        overlapping = {
          started_at: '2016-09-30T10:30:00.836+0200',
          stopped_at: '2016-09-30T11:30:00.620+0200',
          nature:     'intervention'
        }

        working_periods = [
          {
            started_at: '2016-09-30T11:00:00.320+0200',
            stopped_at: '2016-09-30T12:00:00.770+0200',
            nature:     'preparation'
          },
          {
            started_at: '2016-09-30T11:30:00.770+0200',
            stopped_at: '2016-09-30T12:30:00.836+0200',
            nature:     'travel'
          }
        ]

        {
          request_intervention_id: request.id,
          request_compliant: 1,
          uuid: '1d5fd107-7321-49d3-915f-88ab27599d9f',
          state: state.to_s,
          procedure_name: procedure.to_s,
          device_uid: 'android:dd60319e524d3d24',
          working_periods: only_overlap ? [overlapping] : working_periods
        }
      end

      def repeating_payload(state: :done, procedure: :plant_watering, action: :irrigation)
        request = Intervention.create!(nature: :request, procedure_name: procedure, actions: [action])
        {
          request_intervention_id: request.id,
          request_compliant: 1,
          uuid: '1d5fd107-7321-49d3-915f-88ab27599d9f',
          state: state.to_s,
          procedure_name: procedure.to_s,
          device_uid: 'android:dd60319e524d3d24',
          working_periods:
          [
            {
              started_at: '2016-09-30T11:59:49.320+0200',
              stopped_at: '2016-09-30T11:59:50.770+0200',
              nature:     'preparation'
            },
            {
              started_at: '2016-09-30T11:59:49.320+0200',
              stopped_at: '2016-09-30T11:59:50.770+0200',
              nature:     'preparation'
            },
            {
              started_at: '2016-09-30T11:59:49.320+0200',
              stopped_at: '2016-09-30T11:59:50.770+0200',
              nature:     'preparation'
            },
            {
              started_at: '2016-09-30T11:59:52.620+0200',
              stopped_at: '2016-09-30T11:59:55.903+0200',
              nature:     'travel'
            }
          ]
        }
      end
    end
  end
end