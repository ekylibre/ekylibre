require 'test_helper'

module Backend
  class ActivityProductionsControllerTest < ActionController::TestCase
    test_restfully_all_actions new: { params: { activity_id: 1, campaign_id: 6 } }, except: :create


    test 'create action' do
      activity_production = activity_productions(:activity_productions_001)
      post :create, {:activity_production=>{created_at: activity_production.created_at, updated_at: activity_production.updated_at, lock_version: activity_production.lock_version, usage: activity_production.usage, size_value: activity_production.size_value, size_indicator_name: activity_production.size_indicator_name, size_unit_name: activity_production.size_unit_name, irrigated: activity_production.irrigated, nitrate_fixing: activity_production.nitrate_fixing, support_shape: activity_production.support_shape, support_nature: activity_production.support_nature, started_on: activity_production.started_on, stopped_on: activity_production.stopped_on, state: activity_production.state, rank_number: activity_production.rank_number, custom_fields: activity_production.custom_fields, :activity_id=>1, :campaign_id=>6}, :locale=>@locale}
    end
  end
end
