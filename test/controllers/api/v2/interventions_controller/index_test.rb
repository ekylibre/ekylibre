require 'test_helper'
require 'ffaker'

module Api
  module V2
    class InterventionsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
      connect_with_token

      test 'index' do
        get :index, params: {}
        assert_response :ok
        assert json_response.size <= 30

        get :index, params: { page: 2 }
        assert_response :ok
        assert json_response.size <= 30

        get :index, params: { contact_email: 'support@ekylibre.com' }
        assert_response :ok
        assert json_response.size <= 30

        get :index, params: { user_email: 'admin@ekylibre.org' }
        assert_response :ok
        assert json_response.size <= 30

        get :index, params: { user_email: 'admin@ekylibre.org', nature: 'request', with_interventions: 'true' }
        assert_response :ok
        assert json_response.size <= 30

        get :index, params: { user_email: 'admin@ekylibre.org', nature: 'request', with_interventions: 'false' }
        assert_response :ok
        assert json_response.size <= 30

        get :index, params: { user_email: 'admin@ekylibre.org', nature: 'request', with_interventions: 'falsesd' }
        assert_response :unprocessable_entity
      end

      test 'filter with user worker' do
        worker = create(:entity, :client, :transporter)
        user_with_worker = create(:user, :employed, person: worker)
        create(:worker, person: worker)

        user_without_worker = create(:user)

        get :index, params: { user_email: user_with_worker.email }
        assert_response :ok
        assert json_response.size <= 30

        wrong_email = 'wrong-email@test.com'
        get :index, params: { user_email: wrong_email }
        assert_response :unprocessable_entity
        assert json_response['errors']
        assert json_response['errors'].include? :no_user_with_email.tn(email: wrong_email)

        get :index, params: { user_email: user_without_worker.email }
        json = JSON.parse response.body
        assert_response :precondition_required
        assert json_response['errors']
        assert json_response['errors'].include? :no_worker_associated_with_user_account.tn
      end

      test 'filter with entity worker' do
        entity_with_worker = create(:entity, :with_email, :worker)
        entity_without_worker = create(:entity, :with_email)

        get :index, params: { contact_email: entity_with_worker.emails.first.coordinate }
        assert_response :ok
        assert json_response.size <= 30

        wrong_email = 'wrong-email@test.com'
        get :index, params: { contact_email: wrong_email }
        assert_response :unprocessable_entity
        assert json_response['errors']
        assert json_response['errors'].include? :no_entity_with_email.tn(email: wrong_email)

        get :index, params: { contact_email: entity_without_worker.emails.first.coordinate }
        assert_response :precondition_required
        assert json_response['errors']
        assert json_response['errors'].include? :no_worker_associated_with_entity_account.tn
      end
    end
  end
end
