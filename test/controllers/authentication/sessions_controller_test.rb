require 'test_helper'
class Authentication::SessionsControllerTest < ActionController::TestCase
  setup do
    @request.env['devise.mapping'] = Devise.mappings[:user]
  end

  test 'approved user can sign in' do
    approved_user = users(:users_001)
    post :create, user: { email: approved_user.email, password: '12345678' }
    assert_redirected_to /\A#{backend_root_url}/
  end

  test 'unapproved user can not sign in' do
    unapproved_user = users(:users_001)
    unapproved_user.update_column(:signup_at, Time.now)

    post :create, user: { email: unapproved_user.email, password: '12345678' }
    assert_redirected_to new_user_session_path
    assert_not_nil flash[:alert]
  end
end
