require 'test_helper'

module Backend
  class TargetDistributionsControllerTest < ActionController::TestCase
    test_restfully_all_actions except: :create

    def create
      target_distribution = target_distributions(:target_distributions_001)
      post :create, target_distribution: { started_at: target_distribution.started_at, stopped_at: target_distribution.stopped_at, created_at: target_distribution.created_at, updated_at: target_distribution.updated_at, lock_version: target_distribution.lock_version, activity_id: target_distribution.activity_id, activity_production: target_distribution.activity_production_id, target_id: target_distribution.target_id }, locale: @locale
    end
  end
end
