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
    js_logout
  end

  setup do
    login_with_user(after_login_path: '/backend')
  end

  teardown do
    Warden.test_reset!
  end

  test 'create invitation' do
    create_invitation
  end
end
