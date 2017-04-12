# coding: utf-8

require 'test_helper'

class EkylibreOauthSignInTest < CapybaraIntegrationTest
  setup do
    OmniAuth.config.test_mode = true
  end

  test 'sign in' do
    omniauth_mock

    visit(new_user_session_path)
    click_on('Sign in with Ekylibre.com')
    assert has_content?('Home dashboard'), 'User should be logged'
    js_logout
  end

  test 'sign in with unknown user' do
    omniauth_mock(email: 'invalid_user@ekylibre.org')

    visit(new_user_session_path)
    click_on('Sign in with Ekylibre.com')
    assert has_no_content?('Home dashboard'), 'User should not be logged'
    assert has_content?('Sign in'), 'User should see the sign in form'
    assert has_content?('Invalid email or password.'), 'User should see error message'
  end

  test 'sign in with oauth failure' do
    OmniAuth.config.mock_auth[:ekylibre] = :invalid_credentials

    visit(new_user_session_path)
    click_on('Sign in with Ekylibre.com')
    assert has_no_content?('Home dashboard'), 'User should not be logged'
    assert has_content?('Sign in'), 'User should see the sign in form'
    assert has_content?(/Could not authenticate you from Ekylibre because.*Invalid credentials/), 'User should see error message'
  end

  test 'sign in after invitation' do
    omniauth_mock(email: 'invitee@ekylibre.org')

    create_invitation(email: 'invitee@ekylibre.org')
    sleep 1
    accept_invitation_path = find_accept_invitation_path

    invitation_token = URI.parse(accept_invitation_path)
                          .query.match(/\Ainvitation_token=(\w+)\z/)[1]

    visit(accept_invitation_path)
    assert has_content?('Set your password'), 'User see set your password'

    assert has_link?(
      'Sign in with Ekylibre.com',
      href: user_ekylibre_omniauth_authorize_path(
        invitation_token: invitation_token
      )
    ), 'Oauth sign in path includes invitation token'

    click_on('Sign in with Ekylibre.com')
    assert has_content?('Home dashboard'), 'User should be logged'
    js_logout
  end

  teardown do
    Warden.test_reset!
  end
end
