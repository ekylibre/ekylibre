require 'test_helper'
class Authentication::OmniauthCallbacksControllerTest < ActionController::TestCase
  setup do
    OmniAuth.config.test_mode = true
    @invitee = User.invite!(
      first_name: 'Robert',
      last_name: 'Tee',
      email: 'robert.tee@ekylibre.org',
      role: Role.first,
      language: 'eng',
      skip_invitation: true
    )

    @request.env['devise.mapping'] = Devise.mappings[:user]
    request.env['omniauth.auth'] = omniauth_mock(
      first_name: 'Robert',
      last_name: 'Tee',
      email: 'robert.tee@ekylibre.org'
    )
  end

  test 'invited user can sign in' do
    assert !@invitee.invitation_accepted?

    get :ekylibre, invitation_token: @invitee.raw_invitation_token
    assert_redirected_to(/\A#{backend_root_url}/)
    assert @invitee.reload.invitation_accepted?
  end

  test 'invited user can not sign in with unknown invitation token' do
    assert !@invitee.invitation_accepted?

    get :ekylibre, invitation_token: 'unknown'
    assert_redirected_to accept_user_invitation_path(invitation_token: 'unknown')
    assert !@invitee.reload.invitation_accepted?
  end

  test 'invited user can not sign in without an invitation token' do
    assert !@invitee.invitation_accepted?

    get :ekylibre
    assert_redirected_to accept_user_invitation_path
    assert !@invitee.reload.invitation_accepted?
  end

  test 'invited user can not sign in with a different invitation token' do
    invitee_2 = User.invite!(
      first_name: 'Brue',
      last_name: 'Lee',
      email: 'bruce.lee@ekylibre.org',
      role: Role.first,
      language: 'eng',
      skip_invitation: true
    )

    assert !@invitee.invitation_accepted?
    assert !invitee_2.invitation_accepted?

    get :ekylibre, invitation_token: invitee_2.raw_invitation_token
    assert_redirected_to accept_user_invitation_path(invitation_token: invitee_2.raw_invitation_token)
    assert !@invitee.reload.invitation_accepted?
    assert !invitee_2.reload.invitation_accepted?
  end
end
