require 'test_helper'
module Api
  module V1
    module BasicBehaviourTest
      extend ActiveSupport::Concern
      included do
        test 'receiving an empty payload doesn\'t blow up' do
          add_auth_header

          assert_nothing_raised { post :create }
        end

        test 'receiving an appropriate payload creates an appropriate InterventionParticipation and returns its id' do
          add_auth_header
          payload = correct_payload

          part_id = JSON(post(:create, payload).body)['id']
          assert_not_nil part_id
          assert_not_nil part = InterventionParticipation.find_by(id: part_id)

          assert_equal true, part.request_compliant
          assert_equal 9, part.working_periods.count
          assert_equal :done, part.state.to_sym
        end

        test 'receiving a payload doesn\'t generate an InterventionParticipation if not needed' do
          add_auth_header
          payload = correct_payload

          part_id_una = JSON(post(:create, payload).body)['id']
          part_id_bis = JSON(post(:create, payload).body)['id']

          assert_not_nil part_id_una
          assert_not_nil part_id_bis
          assert_equal part_id_una, part_id_bis
        end

        test 'handles completely wrong payload graciously' do
          add_auth_header

          assert_nothing_raised { post :create, params: { yolo: :swag, test: [:bidouille, 'le malin', 1_543_545], 54 => 1_014_441 } }
        end
      end
    end

    module InterventionCreationTest
      extend ActiveSupport::Concern
      included do
        test 'instantiate an intervention if it doesn\'t exist' do
          add_auth_header

          original_count = Intervention.where(nature: :record).count
          payload = correct_payload
          post :create, payload

          assert_equal original_count + 1, Intervention.where(nature: :record).count
        end

        test 'doesn\'t instantiate an intervention if a fitting one exists' do
          add_auth_header
          payload = correct_payload

          post :create, payload
          original_count = Intervention.count

          post :create, payload
          new_count = Intervention.count

          assert_equal original_count, new_count
        end
      end
    end

    module WorkingPeriodsTest
      extend ActiveSupport::Concern
      included do
        test 'ignores working periods that already exist' do
          add_auth_header
          request_intervention = create(:intervention,
                                        :with_working_period,
                                        procedure_name: :plant_watering,
                                        actions: [:irrigation],
                                        nature: :request
                                       )
          payload = {
            intervention_id: request_intervention.id,
            request_compliant: 1,
            uuid: '1d5fd107-7321-49d3-915f-88ab27599d9f',
            state: 'done',
            procedure_name: 'plant_watering',
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
          response = JSON(post(:create, payload).body)
          part_id = response['id']
          original_count = InterventionParticipation.find(part_id).working_periods.count

          part_id = JSON(post(:create, payload).body)['id']
          new_count = InterventionParticipation.find(part_id).working_periods.count

          assert_equal original_count, new_count
        end

        test 'ignores overlapping working periods' do
          add_auth_header
          payload = overlapping_payload

          part_id = JSON(post(:create, payload).body)['id']
          original_count = InterventionParticipation.find(part_id).working_periods.count

          assert_equal 1, original_count

          payload = overlapping_payload(only_overlap: true)
          part_id = JSON(post(:create, payload).body)['id']
          new_count = InterventionParticipation.find(part_id).working_periods.count

          assert_equal original_count, new_count
        end

        test 'created working_periods have the correct nature' do
          add_auth_header

          payload = correct_payload
          part_id = JSON(post(:create, payload).body)['id']
          natures = InterventionParticipation.find(part_id).working_periods.order(:started_at).pluck(:nature).map(&:to_sym)

          assert_equal %i[preparation travel intervention travel preparation travel intervention travel preparation], natures
        end

        private

        def overlapping_payload(only_overlap: false)
          request_intervention = create(:intervention,
                                        :with_working_period,
                                        procedure_name: :plant_watering,
                                        actions: [:irrigation],
                                        nature: :request
                                       )
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
            intervention_id: request_intervention.id,
            request_compliant: 1,
            uuid: '1d5fd107-7321-49d3-915f-88ab27599d9f',
            state: 'done',
            procedure_name: 'plant_watering',
            device_uid: 'android:dd60319e524d3d24',
            working_periods: only_overlap ? [overlapping] : working_periods
          }
        end
      end
    end

    module HourCounterTest
      extend ActiveSupport::Concern
      included do
        test 'add hour counter on intervention tools from request intervention to done intervention' do
          default_setup
          payload = {
            working_periods: [
              {
                started_at: "2019-08-01T12:15:28.108+0200",
                stopped_at: "2019-08-01T12:15:31.672+0200",
                nature: "preparation"
              },
              {
                started_at: "2019-08-01T12:15:31.672+0200",
                stopped_at: "2019-08-01T12:15:35.728+0200",
                nature: "travel"
              },
              {
                started_at: "2019-08-01T12:15:35.728+0200",
                stopped_at: "2019-08-01T12:15:41.456+0200",
                nature: "intervention"
              }
            ],
            equipments: [
              {
                product_id: @tractor_ids.first,
                hour_counter: 45
              },
              {
                product_id: @tractor_ids.last,
                hour_counter: 72
              }
            ],
            state: "done",
            device_uid: "android:46b9fb83a04c19ff",
            intervention_id: @request_intervention.id
          }
          post :create, payload
          assert_response :created
          participation_id = JSON.parse(response.body)['id']
          intervention = InterventionParticipation.find(participation_id).intervention
          assert_equal 'done', intervention.state
          assert_equal @request_intervention.record_interventions.last, intervention
          assert_equal 2, intervention.tools.count
          tractor1 = intervention.tools.find_by(product_id: @tractor_ids.first)
          assert_equal 45, tractor1.readings.last.measure_value_value
          tractor2 = intervention.tools.find_by(product_id: @tractor_ids.last)
          assert_equal 72, tractor2.readings.last.measure_value_value
        end

        test 'add hour counter on intervention tools from in_progress intervention to done intervention' do
          default_setup
          payload = {
            # First step : create an 'in_progress' intervention which correspond to a paused intervention in the mobile app
            working_periods: [
              {
                started_at: "2019-08-01T12:15:28.108+0200",
                stopped_at: "2019-08-01T12:15:31.672+0200",
                nature: "preparation"
              },
              {
                started_at: "2019-08-01T12:15:31.672+0200",
                stopped_at: "2019-08-01T12:15:35.728+0200",
                nature: "travel"
              },
              {
                started_at: "2019-08-01T12:15:35.728+0200",
                stopped_at: "2019-08-01T12:15:41.456+0200",
                nature: "intervention"
              }
            ],
            state: "in_progress",
            device_uid: "android:46b9fb83a04c19ff",
            intervention_id: @request_intervention.id
          }
          post :create, payload
          assert_response :created
          participation_id = JSON.parse(response.body)['id']
          intervention = InterventionParticipation.find(participation_id).intervention
          assert_equal 'in_progress', intervention.state
          # Second step : update the 'in_progress' intervention to a 'done' intervention and assign hour counters on tools
          payload = {
            working_periods: [
              {
                started_at: "2019-08-01T12:15:28.108+0200",
                stopped_at: "2019-08-01T12:15:31.672+0200",
                nature: "preparation"
              },
              {
                started_at: "2019-08-01T12:15:31.672+0200",
                stopped_at: "2019-08-01T12:15:35.728+0200",
                nature: "travel"
              },
              {
                started_at: "2019-08-01T12:15:35.728+0200",
                stopped_at: "2019-08-01T12:15:41.456+0200",
                nature: "intervention"
              }
            ],
            equipments: [
              {
                product_id: @tractor_ids.first,
                hour_counter: 45
              },
              {
                product_id: @tractor_ids.last,
                hour_counter: 72
              }
            ],
            state: "done",
            device_uid: "android:46b9fb83a04c19ff",
            intervention_id: @request_intervention.id
          }
          post :create, payload
          assert_response :created
          participation_id = JSON.parse(response.body)['id']
          intervention = InterventionParticipation.find(participation_id).intervention
          assert_equal 'done', intervention.state
          assert_equal @request_intervention.record_interventions.last, intervention
          assert_equal 2, intervention.tools.count
          tractor1 = intervention.tools.find_by(product_id: @tractor_ids.first)
          assert_equal 45, tractor1.readings.last.measure_value_value
          tractor2 = intervention.tools.find_by(product_id: @tractor_ids.last)
          assert_equal 72, tractor2.readings.last.measure_value_value
        end

        test 'add hour counter on intervention tools from request intervention to in_progress intervention should return error' do
          default_setup
          payload = {
            working_periods: [
              {
                started_at: "2019-08-01T12:15:28.108+0200",
                stopped_at: "2019-08-01T12:15:31.672+0200",
                nature: "preparation"
              },
              {
                started_at: "2019-08-01T12:15:31.672+0200",
                stopped_at: "2019-08-01T12:15:35.728+0200",
                nature: "travel"
              },
              {
                started_at: "2019-08-01T12:15:35.728+0200",
                stopped_at: "2019-08-01T12:15:41.456+0200",
                nature: "intervention"
              }
            ],
            equipments: [
              {
                product_id: @tractor_ids.first,
                hour_counter: 45
              },
              {
                product_id: @tractor_ids.last,
                hour_counter: 72
              }
            ],
            state: "in_progress",
            device_uid: "android:46b9fb83a04c19ff",
            intervention_id: @request_intervention.id
          }
          post :create, payload
          assert_response :bad_request
        end

        test 'invalid equipments payload should return error' do
          default_setup
          payload = {
            working_periods: [
              {
                started_at: "2019-08-01T12:15:28.108+0200",
                stopped_at: "2019-08-01T12:15:31.672+0200",
                nature: "preparation"
              },
              {
                started_at: "2019-08-01T12:15:31.672+0200",
                stopped_at: "2019-08-01T12:15:35.728+0200",
                nature: "travel"
              },
              {
                started_at: "2019-08-01T12:15:35.728+0200",
                stopped_at: "2019-08-01T12:15:41.456+0200",
                nature: "intervention"
              }
            ],
            equipments: [
              {
                product_id: @tractor_ids.first,
                hour_counter: 45
              },
              {
                product_id: @tractor_ids.last
                # hour_counter value should be here
              }
            ],
            state: "in_progress",
            device_uid: "android:46b9fb83a04c19ff",
            intervention_id: @request_intervention.id
          }
          post :create, payload
          assert_response :bad_request
        end

        test 'invalid product_id on equipments payload should return error' do
          default_setup
          payload = {
            working_periods: [
              {
                started_at: "2019-08-01T12:15:28.108+0200",
                stopped_at: "2019-08-01T12:15:31.672+0200",
                nature: "preparation"
              },
              {
                started_at: "2019-08-01T12:15:31.672+0200",
                stopped_at: "2019-08-01T12:15:35.728+0200",
                nature: "travel"
              },
              {
                started_at: "2019-08-01T12:15:35.728+0200",
                stopped_at: "2019-08-01T12:15:41.456+0200",
                nature: "intervention"
              }
            ],
            equipments: [
              {
                # random product_id here
                product_id: @tractor_ids.first + 123456789,
                hour_counter: 45
              },
              {
                product_id: @tractor_ids.last,
                hour_counter: 72
              }
            ],
            state: "in_progress",
            device_uid: "android:46b9fb83a04c19ff",
            intervention_id: @request_intervention.id
          }
          post :create, payload
          assert_response :bad_request
        end

        private

        def default_setup
          add_auth_header
          @request_intervention = create(:intervention,
                                        :with_tractor_tool,
                                        nature: :request
                                       )
          @tractor_ids = @request_intervention.tools.map(&:product_id)
          assert_equal 2, @tractor_ids.count
        end
      end
    end

    class InterventionParticipationsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
      connect_with_token

      include BasicBehaviourTest
      include InterventionCreationTest
      include WorkingPeriodsTest
      include HourCounterTest

      private

      def correct_payload(state: :done, procedure: :plant_watering)
        request_intervention = create(:intervention,
                                      :with_working_period,
                                      procedure_name: :plant_watering,
                                      actions: [:irrigation],
                                      nature: :request
                                     )
        {
          intervention_id: request_intervention.id,
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


      # def repeating_payload(state: :done, procedure: :plant_watering, action: :irrigation)
        # {
          # intervention_id: @intervention_request.id,
          # request_compliant: 1,
          # uuid: '1d5fd107-7321-49d3-915f-88ab27599d9f',
          # state: state.to_s,
          # procedure_name: procedure.to_s,
          # device_uid: 'android:dd60319e524d3d24',
          # working_periods:
          # [
            # {
              # started_at: '2016-09-30T11:59:49.320+0200',
              # stopped_at: '2016-09-30T11:59:50.770+0200',
              # nature:     'preparation'
            # },
            # {
              # started_at: '2016-09-30T11:59:49.320+0200',
              # stopped_at: '2016-09-30T11:59:50.770+0200',
              # nature:     'preparation'
            # },
            # {
              # started_at: '2016-09-30T11:59:49.320+0200',
              # stopped_at: '2016-09-30T11:59:50.770+0200',
              # nature:     'preparation'
            # },
            # {
              # started_at: '2016-09-30T11:59:52.620+0200',
              # stopped_at: '2016-09-30T11:59:55.903+0200',
              # nature:     'travel'
            # }
          # ]
        # }
      # end
    end
  end
end
