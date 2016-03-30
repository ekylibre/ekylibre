# coding: utf-8
require 'test_helper'

class FrontendInvitations < CapybaraIntegrationTest
  def create_invitation
    visit("/authentication/sign_in?locale=#{@locale}")
    login_as(users(:users_001), scope: :user) # , run_callbacks: false
    visit('/backend/invitations/new')
    fill_in('user[first_name]', with: 'Robert')
    fill_in('user[last_name]', with: 'Tee')
    fill_in('user[email]', with: 'invitee@ekylibre.org')
    click_on(:create.tl)
    script = "$('a.signout').click()"
    execute_script(script)
  end

  def find_accept_invitation_path
    mail_body = ActionMailer::Base.deliveries.first.body.to_s
    URI(URI.extract(mail_body).first).request_uri
  end

  setup do
    I18n.locale = @locale = ENV['LOCALE'] || I18n.default_locale
  end

  teardown do
    Warden.test_reset!
  end

  test 'accept invitation' do
    create_invitation

    accept_invitation_path = find_accept_invitation_path

    visit(accept_invitation_path)
    fill_in 'Password', with: 'robert00'
    fill_in 'Confirmation of password', with: 'robert00'
    click_on('Set my password')
    assert has_content?('Home dashboard'), 'Invitee should be logged'
  end
end
