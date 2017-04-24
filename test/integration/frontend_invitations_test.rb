# coding: utf-8

require 'test_helper'

class FrontendInvitations < CapybaraIntegrationTest
  setup do
    I18n.locale = @locale = ENV['LOCALE'] || I18n.default_locale
  end

  teardown do
    Warden.test_reset!
  end

  test 'accept invitation' do
    create_invitation
    accept_invitation_path = find_accept_invitation_path

    visit(accept_invitation_path + '&locale=eng')
    shoot_screen 'invitations/list'
    fill_in 'Password', with: 'robert00'
    fill_in 'Confirmation of password', with: 'robert00'
    click_on('Set my password')
    assert has_content?('Home dashboard'), 'Invitee should be logged'
    js_logout
  end
end
