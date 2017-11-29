require 'test_helper'
module Authentication
  class SessionsControllerTest < ActionController::TestCase
    setup do
      @request.env['devise.mapping'] = Devise.mappings[:user]
    end

    # TODO: Re-activate the following

    # test 'approved user can sign in' do
    #   approved_user = users(:users_001)
    #   post :create, params: { user: { email: approved_user.email, password: '12345678' } }
    #   assert_redirected_to /\A#{backend_root_url}/
    # end

    # TODO: Re-activate the following

    # test 'unapproved user can not sign in' do
    #   unapproved_user = users(:users_001)
    #   unapproved_user.update_column(:signup_at, Time.now)

    #   post :create, params: { user: { email: unapproved_user.email, password: '12345678' } }
    #   assert_redirected_to new_user_session_path
    #   assert_not_nil flash[:alert]
    # end
  end
end
