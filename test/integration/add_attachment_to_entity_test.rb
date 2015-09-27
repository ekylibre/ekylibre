require 'test_helper'

class AddAttachmentToEntity < CapybaraIntegrationTest
  setup do
    # Need to go on page to set tenant
    I18n.locale = @locale = ENV['LOCALE'] || I18n.default_locale
    visit("/authentication/sign_in?locale=#{@locale}")
    resize_window(1366, 768)
    login_as(users(:users_001), scope: :user)
  end

  teardown do
    Warden.test_reset!
  end

  test 'should add an attachment to an entity' do

    entity = entities(:entities_001)

    visit(backend_entity_path(entity))
    wait_for_ajax

    assert find('#title').text().include? entity.full_name

  end


end
