require 'test_helper'
module Api
  module V1
    module BasicBehaviourTest
      extend ActiveSupport::Concern
      included do
        test 'receiving an empty payload doesn\'t blow up' do

          assert_nothing_raised { post :create }
        end

        test 'receiving an appropriate payload creates an appropriate InterventionParticipation and returns its id' do
          payload = correct_payload

          post :create, params: payload
          assert_response :created

          part_id = JSON(response.body)['id']
          assert_not_nil part_id
          assert_not_nil part = InterventionParticipation.find_by(id: part_id)

          assert_equal true, part.request_compliant
          assert_equal 9, part.working_periods.count
          assert_equal :done, part.state.to_sym
        end

        test 'receiving a payload doesn\'t generate an InterventionParticipation if not needed' do
          payload = correct_payload

          r1 = post(:create, params: payload)
          assert_response :created, response.body
          r2 = post(:create, params: payload)
          assert_response :created

          part_id_una = JSON(r1.body)['id']
          part_id_bis = JSON(r2.body)['id']

          assert_not_nil part_id_una
          assert_not_nil part_id_bis
          assert_equal part_id_una, part_id_bis
        end

        test 'handles completely wrong payload graciously' do

          assert_nothing_raised { post :create, params: { yolo: :swag, test: [:bidouille, 'le malin', 1_543_545], 54 => 1_014_441 } }
        end

        test 'can finish an intervention even if there is no working periods' do
          payload = payload_without_working_periods
          request_intervention_id = payload[:intervention_id]
          request_intervention = Intervention.find(request_intervention_id)
          post :create, params: payload

          done_intervention = request_intervention.record_interventions.first
          assert_not_nil done_intervention
          assert_equal 'done', done_intervention.state
        end

        test 'can pause then finish an intervention even if there is no working periods' do
          in_progress_payload = payload_without_working_periods(state: :in_progress)
          request_intervention_id = in_progress_payload[:intervention_id]
          request_intervention = Intervention.find(request_intervention_id)
          post :create, params: in_progress_payload

          in_progress_intervention = request_intervention.record_interventions.first
          assert_not_nil in_progress_intervention
          assert_equal 'in_progress', in_progress_intervention.state

          done_payload = in_progress_payload.merge(state: :done)
          post :create, params: done_payload

          done_intervention = request_intervention.record_interventions.first
          assert_equal in_progress_intervention, done_intervention
          assert_equal 'done', done_intervention.state
        end

        test 'participation with no working periods do not recalculate intervention working periods' do
          payload = payload_without_working_periods
          request_intervention_id = payload[:intervention_id]
          request_intervention = Intervention.find(request_intervention_id)
          post :create, params: payload

          done_intervention = request_intervention.record_interventions.first
          assert_not_nil done_intervention
          assert_equal request_intervention.started_at, done_intervention.started_at
          assert_equal request_intervention.stopped_at, done_intervention.stopped_at
        end

        private

          def payload_without_working_periods(state: :done)
            correct_payload(state: state).except(:working_periods)
          end
      end
    end

    module InterventionCreationTest
      extend ActiveSupport::Concern
      included do
        test 'instantiate an intervention if it doesn\'t exist' do

          original_count = Intervention.where(nature: :record).count
          payload = correct_payload
          post :create, params: payload
          assert_response :created

          assert_equal original_count + 1, Intervention.where(nature: :record).count
        end

        test 'doesn\'t instantiate an intervention if a fitting one exists' do
          payload = correct_payload

          post :create, params: payload
          original_count = Intervention.count

          post :create, params: payload
          new_count = Intervention.count

          assert_equal original_count, new_count
        end
      end
    end

    module WorkingPeriodsTest
      extend ActiveSupport::Concern
      included do
        test 'no error should be raised if no working_periods are provided' do
          payload = correct_payload.except(:working_periods)

          assert_nothing_raised { post :create, params: payload }
        end

        test 'ignores working periods that already exist' do
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
                  started_at: Time.new(2016, 9, 30, 11, 59, 49),
                  stopped_at: Time.new(2016, 9, 30, 11, 59, 50),
                  nature: 'preparation'
                },
                {
                  started_at: Time.new(2016, 9, 30, 11, 59, 49),
                  stopped_at: Time.new(2016, 9, 30, 11, 59, 50),
                  nature: 'preparation'
                },
                {
                  started_at: Time.new(2016, 9, 30, 11, 59, 49),
                  stopped_at: Time.new(2016, 9, 30, 11, 59, 50),
                  nature: 'preparation'
                },
                {
                  started_at: Time.new(2016, 9, 30, 11, 59, 52),
                  stopped_at: Time.new(2016, 9, 30, 11, 59, 55),
                  nature: 'travel'
                }
              ]
          }

          resp = post(:create, params: payload)
          assert_response :created

          response = JSON(resp.body)
          part_id = response['id']
          original_count = InterventionParticipation.find(part_id).working_periods.count

          resp = post(:create, params: payload)
          assert_response :created

          part_id = JSON(resp.body)['id']
          new_count = InterventionParticipation.find(part_id).working_periods.count

          assert_equal original_count, new_count
        end

        test 'ignores overlapping working periods' do
          payload = overlapping_payload

          resp = post(:create, params: payload)
          assert_response :created

          part_id = JSON(resp.body)['id']
          original_count = InterventionParticipation.find(part_id).working_periods.count

          assert_equal 1, original_count

          payload = overlapping_payload(only_overlap: true)
          part_id = JSON(post(:create, params: payload).body)['id']
          new_count = InterventionParticipation.find(part_id).working_periods.count

          assert_equal original_count, new_count
        end

        test 'created working_periods have the correct nature' do
          payload = correct_payload
          resp = post(:create, params: payload)
          assert_response :created

          part_id = JSON(resp.body)['id']
          natures = InterventionParticipation.find(part_id).working_periods.order(:started_at).pluck(:nature).map(&:to_sym)

          assert_equal %i[preparation travel intervention travel preparation travel intervention travel preparation], natures
        end

        test 'working periods without pause of participation override intervention working periods' do

          working_periods = [
            {
              started_at: Time.new(2020, 2, 1, 11, 15),
              stopped_at: Time.new(2020, 2, 1, 12, 15),
              nature: "preparation"
            },
            {
              started_at: Time.new(2020, 2, 1, 12, 15),
              stopped_at: Time.new(2020, 2, 1, 13, 26),
              nature: "travel"
            },
            {
              started_at: Time.new(2020, 2, 1, 14, 58),
              stopped_at: Time.new(2020, 2, 1, 16, 27),
              nature: "intervention"
            }
          ]
          payload = default_payload.merge(working_periods: working_periods)
          request_intervention = Intervention.find(payload[:intervention_id])
          started_at_before_action = request_intervention.started_at
          stopped_at_before_action = request_intervention.stopped_at
          post :create, params: payload

          record_intervention = request_intervention.record_interventions.first
          assert_not_equal record_intervention.started_at, started_at_before_action
          assert_not_equal record_intervention.stopped_at, stopped_at_before_action
          assert_equal record_intervention.started_at.to_datetime, Time.new(2020, 2, 1, 11, 15).to_datetime
          assert_equal record_intervention.stopped_at.to_datetime, Time.new(2020, 2, 1, 16, 27).to_datetime
          assert_equal 2, record_intervention.working_periods.count
        end

        test 'working periods with pause of participation override intervention working periods' do

          in_progress_working_periods = [
            {
              started_at: Time.new(2020, 2, 1, 11, 15),
              stopped_at: Time.new(2020, 2, 1, 12, 15),
              nature: "preparation"
            },
            {
              started_at: Time.new(2020, 2, 1, 12, 15),
              stopped_at: Time.new(2020, 2, 1, 13, 26),
              nature: "travel"
            },
          ]
          in_progress_payload = default_payload.merge(state: :in_progress, working_periods: in_progress_working_periods)
          post :create, params: in_progress_payload

          request_intervention = Intervention.find(in_progress_payload[:intervention_id])
          in_progress_intervention = request_intervention.record_interventions.first
          assert_equal Time.new(2020, 2, 1, 11, 15).to_datetime, in_progress_intervention.started_at.to_datetime
          assert_equal Time.new(2020, 2, 1, 13, 26).to_datetime, in_progress_intervention.stopped_at.to_datetime
          assert_equal 1, in_progress_intervention.working_periods.count

          done_working_periods = [
            {
              started_at: Time.new(2020, 2, 1, 14, 58),
              stopped_at: Time.new(2020, 2, 1, 16, 27),
              nature: "intervention"
            }
          ]
          done_payload = in_progress_payload.merge(state: :done, working_periods: done_working_periods)
          post :create, params: done_payload

          done_intervention = request_intervention.record_interventions.first
          assert_equal in_progress_intervention, done_intervention
          assert_equal Time.new(2020, 2, 1, 11, 15).to_datetime, done_intervention.started_at.to_datetime
          assert_equal Time.new(2020, 2, 1, 16, 27).to_datetime, done_intervention.stopped_at.to_datetime
          assert_equal 2, done_intervention.working_periods.count
        end

        test 'many participations on a single intervention override intervention working periods' do
          working_period_1 = [
            {
              started_at: Time.new(2020, 2, 1, 10),
              stopped_at: Time.new(2020, 2, 1, 12),
              nature: "preparation"
            }
          ]
          payload = default_payload.merge(state: :in_progress, working_periods: working_period_1)
          post :create, params: payload
          user = create(:user)
          switch_user(user) do
            working_period_2 = [
            {
              started_at: Time.new(2020, 2, 1, 11),
              stopped_at: Time.new(2020, 2, 1, 13),
              nature: "preparation"
            }
          ]
            payload.merge!(working_periods: working_period_2)
            post :create, params: payload
          end
          working_period_3 = [
            {
              started_at: Time.new(2020, 2, 1, 14),
              stopped_at: Time.new(2020, 2, 1, 15),
              nature: "preparation"
            }
          ]
          payload.merge!(working_periods: working_period_3)
          post :create, params: payload
          switch_user(user) do
            working_period_4 = [
            {
              started_at: Time.new(2020, 2, 1, 16),
              stopped_at: Time.new(2020, 2, 1, 17),
              nature: "preparation"
            }
          ]
            payload.merge!(working_periods: working_period_4)
            post :create, params: payload
          end
          request_intervention = Intervention.find(payload[:intervention_id])
          intervention = request_intervention.record_interventions.first
          assert_equal Time.new(2020, 2, 1, 10).to_datetime, intervention.started_at.to_datetime
          assert_equal Time.new(2020, 2, 1, 17).to_datetime, intervention.stopped_at.to_datetime
          assert_equal 3, intervention.working_periods.count
          assert_equal 2, intervention.participations.count
        end

        private

          def overlapping_payload(only_overlap: false)
            payload = default_payload

            overlapping = {
              started_at: Time.new(2016, 9, 30, 10, 30),
              stopped_at: Time.new(2016, 9, 30, 11, 30),
              nature: 'intervention'
            }

            working_periods = [
              {
                started_at: Time.new(2016, 9, 30, 11),
                stopped_at: Time.new(2016, 9, 30, 12),
                nature: 'preparation'
              },
              {
                started_at: Time.new(2016, 9, 30, 11, 30),
                stopped_at: Time.new(2016, 9, 30, 12, 30),
                nature: 'travel'
              }
            ]
            payload.merge(working_periods: (only_overlap ? [overlapping] : working_periods))
          end

          def default_payload
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
              state: 'done',
              procedure_name: 'plant_watering',
              device_uid: 'android:dd60319e524d3d24',
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
                started_at: Time.new(2019, 8, 1, 12, 15, 28),
                stopped_at: Time.new(2019, 8, 1, 12, 15, 31),
                nature: "preparation"
              },
              {
                started_at: Time.new(2019, 8, 1, 12, 15, 31),
                stopped_at: Time.new(2019, 8, 1, 12, 15, 35),
                nature: "travel"
              },
              {
                started_at: Time.new(2019, 8, 1, 12, 15, 35),
                stopped_at: Time.new(2019, 8, 1, 12, 15, 41),
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
          post :create, params: payload
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
                started_at: Time.new(2019, 8, 1, 12, 15, 28),
                stopped_at: Time.new(2019, 8, 1, 12, 15, 31),
                nature: "preparation"
              },
              {
                started_at: Time.new(2019, 8, 1, 12, 15, 31),
                stopped_at: Time.new(2019, 8, 1, 12, 15, 35),
                nature: "travel"
              },
              {
                started_at: Time.new(2019, 8, 1, 12, 15, 35),
                stopped_at: Time.new(2019, 8, 1, 12, 15, 41),
                nature: "intervention"
              }
            ],
            state: "in_progress",
            device_uid: "android:46b9fb83a04c19ff",
            intervention_id: @request_intervention.id
          }
          post :create, params: payload
          assert_response :created
          participation_id = JSON.parse(response.body)['id']
          intervention = InterventionParticipation.find(participation_id).intervention
          assert_equal 'in_progress', intervention.state
          # Second step : update the 'in_progress' intervention to a 'done' intervention and assign hour counters on tools
          payload = {
            working_periods: [
              {
                started_at: Time.new(2019, 8, 1, 12, 15, 28),
                stopped_at: Time.new(2019, 8, 1, 12, 15, 31),
                nature: "preparation"
              },
              {
                started_at: Time.new(2019, 8, 1, 12, 15, 31),
                stopped_at: Time.new(2019, 8, 1, 12, 15, 35),
                nature: "travel"
              },
              {
                started_at: Time.new(2019, 8, 1, 12, 15, 35),
                stopped_at: Time.new(2019, 8, 1, 12, 15, 41),
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
          post :create, params: payload
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
                started_at: Time.new(2019, 8, 1, 12, 15, 28),
                stopped_at: Time.new(2019, 8, 1, 12, 15, 31),
                nature: "preparation"
              },
              {
                started_at: Time.new(2019, 8, 1, 12, 15, 31),
                stopped_at: Time.new(2019, 8, 1, 12, 15, 35),
                nature: "travel"
              },
              {
                started_at: Time.new(2019, 8, 1, 12, 15, 35),
                stopped_at: Time.new(2019, 8, 1, 12, 15, 41),
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
          post :create, params: payload
          assert_response :bad_request
        end

        test 'invalid equipments payload should return error' do
          default_setup
          payload = {
            working_periods: [
              {
                started_at: Time.new(2019, 8, 1, 12, 15, 28),
                stopped_at: Time.new(2019, 8, 1, 12, 15, 31),
                nature: "preparation"
              },
              {
                started_at: Time.new(2019, 8, 1, 12, 15, 31),
                stopped_at: Time.new(2019, 8, 1, 12, 15, 35),
                nature: "travel"
              },
              {
                started_at: Time.new(2019, 8, 1, 12, 15, 35),
                stopped_at: Time.new(2019, 8, 1, 12, 15, 41),
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
          post :create, params: payload
          assert_response :bad_request
        end

        test 'invalid product_id on equipments payload should return error' do
          default_setup
          payload = {
            working_periods: [
              {
                started_at: Time.new(2019, 8, 1, 12, 15, 28),
                stopped_at: Time.new(2019, 8, 1, 12, 15, 31),
                nature: "preparation"
              },
              {
                started_at: Time.new(2019, 8, 1, 12, 15, 31),
                stopped_at: Time.new(2019, 8, 1, 12, 15, 35),
                nature: "travel"
              },
              {
                started_at: Time.new(2019, 8, 1, 12, 15, 35),
                stopped_at: Time.new(2019, 8, 1, 12, 15, 41),
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
          post :create, params: payload
          assert_response :bad_request
        end

        private

          def default_setup
            @request_intervention = create(
              :intervention,
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
          intervention_started_at = DateTime.parse('2016-09-30T11:30:49.320+0200')
          intervention_stopped_at = intervention_started_at + 1.hour
          request_intervention = create(:intervention,
                                        :with_working_period,
                                        procedure_name: :plant_watering,
                                        actions: [:irrigation],
                                        nature: :request,
                                        started_at: intervention_started_at,
                                        stopped_at: intervention_stopped_at
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
                  started_at: Time.new(2016, 9, 30, 11, 59, 49),
                  stopped_at: Time.new(2016, 9, 30, 11, 59, 50),
                  nature: 'preparation'
                },
                {
                  started_at: Time.new(2016, 9, 30, 11, 59, 50),
                  stopped_at: Time.new(2016, 9, 30, 11, 59, 51),
                  nature: 'travel'
                },
                {
                  started_at: Time.new(2016, 9, 30, 11, 59, 51),
                  stopped_at: Time.new(2016, 9, 30, 11, 59, 52),
                  nature: 'intervention'
                },
                {
                  started_at: Time.new(2016, 9, 30, 11, 59, 52),
                  stopped_at: Time.new(2016, 9, 30, 11, 59, 53),
                  nature: 'travel'
                },
                {
                  started_at: Time.new(2016, 9, 30, 11, 59, 53),
                  stopped_at: Time.new(2016, 9, 30, 11, 59, 54),
                  nature: 'preparation'
                },
                {
                  started_at: Time.new(2016, 9, 30, 11, 59, 54),
                  stopped_at: Time.new(2016, 9, 30, 11, 59, 55),
                  nature: 'travel'
                },
                {
                  started_at: Time.new(2016, 9, 30, 11, 59, 55),
                  stopped_at: Time.new(2016, 9, 30, 11, 59, 56),
                  nature: 'intervention'
                },
                {
                  started_at: Time.new(2016, 9, 30, 11, 59, 56),
                  stopped_at: Time.new(2016, 9, 30, 11, 59, 57),
                  nature: 'travel'
                },
                {
                  started_at: Time.new(2016, 9, 30, 11, 59, 57),
                  stopped_at: Time.new(2016, 9, 30, 11, 59, 58),
                  nature: 'preparation'
                }
              ]
          }
        end
    end
  end
end
