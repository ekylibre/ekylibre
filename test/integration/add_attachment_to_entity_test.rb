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

    assert find('#title').text.include? entity.full_name

    assert Rails.root.join('test', 'fixture-files', 'sample_image.png').exist?, 'No image to attach'

    assert_not find('.attachment-files').has_selector?('.file')

    # Input file is hidden to user
    script = "$('#attachments').css({position: 'relative', opacity: 1});"
    page.execute_script(script)

    shoot_screen 'attachments/attach_file'

    attach_file('attachments', 'test/fixture-files/sample_image.png')
    shoot_screen 'attachments/upload_file'

    wait_for_ajax

    assert find('.attachment-files').find('.file')

    assert find('.attachment-files').find('.file').find('.file-name').text.include? 'sample_image.png'

    shoot_screen 'attachments/uploaded_file'
  end
end
