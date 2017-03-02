require 'test_helper'

module Authentication
  class RegistrationsControllerTest < ActionController::TestCase
    include ActiveJob::TestHelper

    setup do
      @request.env['devise.mapping'] = Devise.mappings[:user]
    end

    def sign_up_request
      post :create, user: {
        first_name: 'Robert',
        last_name: 'Tee',
        email: 'robert.tee@gmail.com',
        password: 'robert00',
        password_confirmation: 'robert00',
        language: 'eng'
      }
    end

    test 'should create a User with signup_at value' do
      sign_up_request
      user = User.where(first_name: 'Robert', last_name: 'Tee', email: 'robert.tee@gmail.com', language: 'eng').first
      assert_not_nil user
      assert_not_nil user.signup_at
      assert !user.active_for_authentication?
      assert_response :redirect
      assert_equal(flash[:notice], 'You have signed up successfully but your account has not been approved by your administrator yet')
    end

    test 'notifies admins by email' do
      assert_difference 'ActionMailer::Base.deliveries.size', +1 do
        sign_up_request
      end

      mail = ActionMailer::Base.deliveries.last
      assert_equal User.administrators.pluck(:email), mail.to
      assert_equal 'New registration', mail.subject
    end
  end
end
