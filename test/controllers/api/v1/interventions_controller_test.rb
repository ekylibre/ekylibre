require 'test_helper'
require 'ffaker'

module Api
  module V1
    class InterventionsControllerTest < ActionController::TestCase
      connect_with_token

      setup do
        @worker = Entity.create(nature: :contact, last_name: ::FFaker::Name.last_name,
                                first_name: ::FFaker::Name.first_name, supplier: true,
                                transporter: true, supplier_account_id: 266)

        @user_with_worker = User.create(last_name: @worker.last_name,
                                        first_name: @worker.first_name, email: ::FFaker::Internet.email,
                                        language: 'fra', maximal_grantable_reduction_percentage: 1,
                                        password: '12345678', password_confirmation: '12345678', role_id: 1,
                                        person: @worker, employed: true)

        Worker.create(person: @worker, name: @user_with_worker.last_name, number: 1, variant_id: 1, variety: 'worker')

        @user_without_worker = User.create(last_name: ::FFaker::Name.last_name,
                                           first_name: ::FFaker::Name.first_name, email: ::FFaker::Internet.email,
                                           language: 'fra', maximal_grantable_reduction_percentage: 1,
                                           password: '12345678', password_confirmation: '12345678', role_id: 1)
      end

      # TODO: Re-activate following test

      # test 'index' do
      #   add_auth_header
      #   get :index
      #   json = JSON.parse response.body
      #   assert_response :ok
      #   assert json.size <= 30

      #   get :index, params: { page: 2 }
      #   json = JSON.parse response.body
      #   assert_response :ok
      #   assert json.size <= 30

      #   get :index, params: { doer_email: 'admin@ekylibre.org' }
      #   json = JSON.parse response.body
      #   assert_response :ok
      #   assert json.size <= 30

      #   get :index, params: { user_email: 'admin@ekylibre.org' }
      #   json = JSON.parse response.body
      #   assert_response :ok
      #   assert json.size <= 30

      #   get :index, params: { user_email: 'admin@ekylibre.org', nature: 'request', with_interventions: 'true' }
      #   json = JSON.parse response.body
      #   assert_response :ok
      #   assert json.size <= 30

      #   get :index, params: { user_email: 'admin@ekylibre.org', nature: 'request', with_interventions: 'false' }
      #   json = JSON.parse response.body
      #   assert_response :ok
      #   assert json.size <= 30

      #   get :index, params: { user_email: 'admin@ekylibre.org', nature: 'request', with_interventions: 'falsesd' }
      #   assert_response :unprocessable_entity
      # end

      # TODO: Re-activate following test

      # test 'Test user worker' do
      #   add_auth_header

      #   get :index, params: { user_email: @user_with_worker.email }
      #   json = JSON.parse response.body
      #   assert_response :ok
      #   assert json.size <= 30

      #   get :index, params: { user_email: @user_without_worker.email }
      #   json = JSON.parse response.body
      #   assert_response :precondition_required
      #   assert json['message']
      #   assert json['message'].eql? :no_worker_account.tl
      # end
    end
  end
end
