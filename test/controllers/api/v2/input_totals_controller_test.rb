require 'test_helper'
module Api
  module V2
    class InputTotalsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
      connect_with_token

      # Fixtures used for hand-checked totals (campaign 2014):
      # - "Blé tendre Le silo 2013" (production 9) received 0.7477 kg of
      #   "Ammonitre 33,5%  Big Bag" in one fertilizing intervention on its
      #   land parcel (working zone 8.3636 ha);
      # - "Blé tendre Le pallet 2013" (production 8) received 0.6425 kg of the
      #   same product (working zone 5.39 ha).
      setup do
        @silo = ActivityProduction.find_by!(name: 'Blé tendre Le silo 2013')
        @pallet = ActivityProduction.find_by!(name: 'Blé tendre Le pallet 2013')
        @ammonitre = Product.find_by!(name: 'Ammonitre 33,5%  Big Bag')
        @silo_fertilizing = Intervention.find(InterventionInput.of_actor(@ammonitre)
                                                               .of_activity_production(@silo)
                                                               .pluck(:intervention_id).first)
      end

      def row_for(production, product)
        json_response['data'].detect do |row|
          row['activity_production']['id'] == production.id && row['input']['product_id'] == product.id
        end
      end

      test '#index requires authentication' do
        @request.headers['Authorization'] = nil
        get :index, params: { campaign: 2014 }
        assert_response :unauthorized
      end

      test '#index requires a valid campaign' do
        get :index, params: {}
        assert_response :bad_request
        assert(json_response['errors'].any? { |e| e.include?('campaign') })

        get :index, params: { campaign: 'last' }
        assert_response :bad_request
      end

      test '#index returns an empty list for an unknown campaign without creating it' do
        assert_no_difference 'Campaign.count' do
          get :index, params: { campaign: 1066 }
        end
        assert_response :ok
        assert_empty json_response['data']
      end

      test '#index returns hand-checked totals' do
        get :index, params: { campaign: 2014 }
        assert_response :ok

        row = row_for(@silo, @ammonitre)
        assert row, 'expected a row for Ammonitre on Le silo'
        assert_equal({ 'id' => @silo.id, 'name' => @silo.name, 'activity_id' => @silo.activity_id }, row['activity_production'])
        assert_equal @ammonitre.variant_id, row['input']['variant_id']
        assert_equal @ammonitre.name, row['input']['name']
        assert_in_delta 0.7477, row['quantity_value'], 0.00001
        assert_equal 'kilogram', row['quantity_unit']
        assert_in_delta 0.7477, row['conditioning_quantity_value'], 0.00001
        assert_equal 1, row['interventions_count']
        assert_in_delta 8.3636, row['treated_area_value'], 0.00001
        assert_equal 'hectare', row['treated_area_unit']
        # 0.7477 kg x 33.5 % of nitrogen
        assert_in_delta 0.2505, row['nitrogen_value'], 0.00001
        assert_equal 'kilogram', row['nitrogen_unit']

        rows = json_response['data']
        assert_equal rows.sort_by { |r| [r['activity_production']['id'], r['input']['product_id']] }, rows
        seed = rows.detect { |r| r['activity_production']['id'] == @silo.id && r['nitrogen_value'].nil? }
        assert seed, 'inputs without nitrogen concentration have a null nitrogen_value'
        assert_nil seed['nitrogen_unit']
      end

      test '#index splits multi-target interventions with the imputation ratio' do
        silo_target = @silo_fertilizing.targets.of_activity_production(@silo).first
        pallet_target = silo_target.dup
        pallet_target.product = @pallet.support
        pallet_target.position = @silo_fertilizing.parameters.maximum(:position) + 1
        pallet_target.save!(validate: false)
        silo_target.update_columns(imputation_ratio: 0.6)
        pallet_target.update_columns(imputation_ratio: 0.4, working_zone_area_value: 1.5)

        get :index, params: { campaign: 2014, input_product_id: @ammonitre.id }
        assert_response :ok
        assert_equal 2, json_response['data'].size

        silo_row = row_for(@silo, @ammonitre)
        assert_in_delta 0.7477 * 0.6, silo_row['quantity_value'], 0.0001
        assert_equal 1, silo_row['interventions_count']

        pallet_row = row_for(@pallet, @ammonitre)
        assert_in_delta 0.6425 + 0.7477 * 0.4, pallet_row['quantity_value'], 0.0001
        assert_equal 2, pallet_row['interventions_count']
        assert_in_delta 5.39 + 1.5, pallet_row['treated_area_value'], 0.0001
        assert_in_delta (0.6425 + 0.7477 * 0.4) * 0.335, pallet_row['nitrogen_value'], 0.0001
      end

      test '#index excludes rejected interventions' do
        @silo_fertilizing.update_columns(state: 'rejected')
        get :index, params: { campaign: 2014 }
        assert_response :ok
        assert_nil row_for(@silo, @ammonitre)
        assert row_for(@pallet, @ammonitre)
      end

      test '#index filters on productions, activity and input' do
        get :index, params: { campaign: 2014, activity_production_id: @silo.id }
        assert_response :ok
        assert json_response['data'].any?
        assert(json_response['data'].all? { |r| r['activity_production']['id'] == @silo.id })

        get :index, params: { campaign: 2014, activity_id: @silo.activity_id }
        assert_response :ok
        assert(json_response['data'].all? { |r| r['activity_production']['activity_id'] == @silo.activity_id })
        assert row_for(@silo, @ammonitre)

        get :index, params: { campaign: 2014, activity_id: Activity.maximum(:id) + 1000 }
        assert_response :ok
        assert_empty json_response['data']

        get :index, params: { campaign: 2014, input_product_id: @ammonitre.id }
        assert_response :ok
        assert_equal([@pallet.id, @silo.id], json_response['data'].map { |r| r['activity_production']['id'] })
        assert(json_response['data'].all? { |r| r['input']['product_id'] == @ammonitre.id })

        get :index, params: { campaign: 2014, input_product_id: 'abc', activity_production_id: '0' }
        assert_response :bad_request
        assert_equal 2, json_response['errors'].size
      end

      test '#index filters on procedure_name and dates' do
        get :index, params: { campaign: 2014, procedure_name: 'fertilizing' }
        assert_response :ok
        assert_equal [@ammonitre.id], json_response['data'].map { |r| r['input']['product_id'] }.uniq

        get :index, params: { campaign: 2014, procedure_name: 'unknown_procedure_xyz' }
        assert_response :bad_request

        started_at = @silo_fertilizing.started_at
        get :index, params: { campaign: 2014, started_after: started_at.iso8601, started_before: started_at.iso8601 }
        assert_response :ok
        assert row_for(@silo, @ammonitre)
        assert(json_response['data'].all? { |r| r['interventions_count'] == 1 })

        get :index, params: { campaign: 2014, started_after: (started_at + 1.second).iso8601, input_product_id: @ammonitre.id }
        assert_response :ok
        assert_nil row_for(@silo, @ammonitre)

        get :index, params: { campaign: 2014, started_before: 'yesterday' }
        assert_response :bad_request
      end

      test '#index paginates' do
        get :index, params: { campaign: 2014, per_page: 100 }
        all_rows = json_response['data']
        total = all_rows.size
        assert total > 2, 'needs at least 3 rows in campaign 2014'

        get :index, params: { campaign: 2014, per_page: 2, page: 1 }
        assert_equal all_rows.first(2), json_response['data']
        assert_equal({ 'elements' => 2, 'page' => 1, 'per_page' => 2, 'total_elements' => total, 'page_count' => (total / 2.0).ceil },
                     json_response['pagination'])

        get :index, params: { campaign: 2014, per_page: 2, page: 2 }
        assert_equal all_rows[2, 2], json_response['data']

        get :index, params: { campaign: 2014, per_page: 2, page: 10_000 }
        assert_response :ok
        assert_empty json_response['data']

        get :index, params: { campaign: 2014, page: 0 }
        assert_response :bad_request
      end
    end
  end
end
