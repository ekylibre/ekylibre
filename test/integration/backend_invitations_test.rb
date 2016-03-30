# coding: utf-8
require 'test_helper'

class BackendInvitations < CapybaraIntegrationTest
  def create_invitation
    visit('/backend/invitations/new')
    fill_in('user[first_name]', with: 'Robert')
    fill_in('user[last_name]', with: 'Tee')
    fill_in('user[email]', with: 'invitee@ekylibre.org')
    click_on(:create.tl)
    assert has_content?('Robert'), 'Robert must appear in list after creation'
    assert has_content?('Pending'), 'Invitation created should be pending'
  end

  setup do
    I18n.locale = @locale = ENV['LOCALE'] || I18n.default_locale
    visit("/authentication/sign_in?locale=#{@locale}")
    login_as(users(:users_001), scope: :user) # , run_callbacks: false
    visit('/backend')
  end

  teardown do
    Warden.test_reset!
  end

  test 'create invitation' do
    create_invitation
  end
end
