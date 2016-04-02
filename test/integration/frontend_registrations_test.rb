# coding: utf-8
require 'test_helper'

class FrontendRegistrations < CapybaraIntegrationTest

  teardown do
    Warden.test_reset!
  end

  def register
    visit('/authentication/sign_up')
    fill_in 'First name', with: 'Robert'
    fill_in 'Last name', with: 'Tee'
    select('English', from: 'Language')
    fill_in 'Email', with: 'robert.tee@ekylibre.org'
    fill_in 'Password', with: 'robert00'
    fill_in 'Confirmation of password', with: 'robert00'
    click_on('Sign up')
  end

  test 'sign_up as not approved' do
    register
    shoot_screen('registrations/after_sign_up')
    assert has_content?('Home dashboard'), 'User should be logged and redirected to backend'
    # assert has_content?('Sign in'), 'User should be redirected to sign in'
    # assert has_content?(/Information.+account.+not.+approved/), 'User should read the pending approval message'
  end
end
