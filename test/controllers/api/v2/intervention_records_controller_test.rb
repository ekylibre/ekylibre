require 'test_helper'
module Api
  module V2
    class InterventionRecordsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
      connect_with_token

      def recorded_scope
        Intervention.with_nature(:record).where.not(state: :rejected)
      end

      def returned_ids
        json_response['data'].map { |intervention| intervention['id'] }
      end

      test '#index requires authentication' do
        @request.headers['Authorization'] = nil
        get :index, params: {}
        assert_response :unauthorized
      end

      test '#index returns recorded interventions with pagination metadata' do
        get :index, params: {}
        assert_response :ok

        total = recorded_scope.count
        pagination = json_response['pagination']
        assert_equal 1, pagination['page']
        assert_equal 50, pagination['per_page']
        assert_equal total, pagination['total_elements']
        assert_equal [total, 50].min, pagination['elements']
        assert_equal [total, 50].min, json_response['data'].size

        intervention = json_response['data'].first
        %w[id number name procedure_name started_at stopped_at working_duration state description provider targets inputs tools doers].each do |key|
          assert intervention.key?(key), "Missing key #{key}"
        end
      end

      test '#index orders by started_at desc then id desc' do
        get :index, params: { per_page: 100 }
        assert_response :ok
        expected = recorded_scope.reorder(started_at: :desc, id: :desc).limit(100).pluck(:id)
        assert_equal expected, returned_ids
      end

      test '#index excludes rejected interventions and requests' do
        rejected, request = recorded_scope.reorder(:id).limit(2).to_a
        rejected.update_columns(state: 'rejected')
        request.update_columns(nature: 'request')

        get :index, params: { per_page: 100 }
        assert_response :ok
        refute_includes returned_ids, rejected.id
        refute_includes returned_ids, request.id
        assert_equal recorded_scope.count, json_response['pagination']['total_elements']
      end

      test '#index paginates' do
        total = recorded_scope.count
        assert total > 2, 'needs at least 3 recorded interventions in fixtures'

        get :index, params: { per_page: 2, page: 1 }
        first_page = returned_ids
        assert_equal 2, first_page.size
        assert_equal (total / 2.0).ceil, json_response['pagination']['page_count']

        get :index, params: { per_page: 2, page: 2 }
        second_page = returned_ids
        assert_equal 2, json_response['pagination']['page']
        assert_empty first_page & second_page

        get :index, params: { per_page: 2, page: 10_000 }
        assert_response :ok
        assert_empty json_response['data']
      end

      test '#index rejects invalid pagination params' do
        get :index, params: { per_page: 101 }
        assert_response :bad_request
        assert json_response['errors'].any?

        get :index, params: { page: 0 }
        assert_response :bad_request

        get :index, params: { page: 'abc' }
        assert_response :bad_request
      end

      test '#index filters on started_at bounds' do
        dates = recorded_scope.reorder(:started_at).pluck(:started_at)
        after = dates[dates.size / 2]
        before = dates.last

        get :index, params: { started_after: after.iso8601, started_before: before.iso8601, per_page: 100 }
        assert_response :ok
        expected = recorded_scope.where(started_at: after..before).pluck(:id)
        assert_equal expected.sort, returned_ids.sort

        get :index, params: { started_after: 'not-a-date' }
        assert_response :bad_request
        assert json_response['errors'].any? { |e| e.include?('started_after') }
      end

      test '#index filters on procedure_name' do
        procedure_name = recorded_scope.group(:procedure_name).count.max_by(&:last).first

        get :index, params: { procedure_name: procedure_name, per_page: 100 }
        assert_response :ok
        assert_equal recorded_scope.of_nature(procedure_name).pluck(:id).sort, returned_ids.sort
        assert(json_response['data'].all? { |i| i['procedure_name'] == procedure_name })

        get :index, params: { procedure_name: 'unknown_procedure_xyz' }
        assert_response :bad_request
      end

      test '#index filters on target_id' do
        target = InterventionTarget.where(intervention: recorded_scope).where.not(product_id: nil).first
        assert target, 'needs a target in fixtures'

        get :index, params: { target_id: target.product_id, per_page: 100 }
        assert_response :ok
        assert_includes returned_ids, target.intervention_id
        json_response['data'].each do |intervention|
          assert_includes intervention['targets'].map { |t| t['product_id'] }, target.product_id
        end

        get :index, params: { target_id: Product.maximum(:id) + 1000 }
        assert_response :ok
        assert_empty json_response['data']

        get :index, params: { target_id: 'abc' }
        assert_response :bad_request
      end

      test '#index filters on input_product_id' do
        input = InterventionInput.where(intervention: recorded_scope).where.not(product_id: nil).first
        assert input, 'needs an input in fixtures'

        get :index, params: { input_product_id: input.product_id, per_page: 100 }
        assert_response :ok
        assert_includes returned_ids, input.intervention_id
        json_response['data'].each do |intervention|
          assert_includes intervention['inputs'].map { |i| i['product_id'] }, input.product_id
        end
      end

      test '#index filters on campaign' do
        campaign = Campaign.with_interventions.first
        if campaign
          get :index, params: { campaign: campaign.harvest_year, per_page: 100 }
          assert_response :ok
          expected = recorded_scope.of_campaign(campaign).reorder(started_at: :desc, id: :desc).limit(100).pluck(:id)
          assert_equal expected, returned_ids
        end

        get :index, params: { campaign: 1066 }
        assert_response :ok
        assert_empty json_response['data']

        get :index, params: { campaign: 'last' }
        assert_response :bad_request
      end
    end
  end
end
