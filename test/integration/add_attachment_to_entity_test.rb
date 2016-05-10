require 'test_helper'

class AddAttachmentToEntity < CapybaraIntegrationTest
  setup do
    login_with_user
  end

  teardown do
    Warden.test_reset!
  end

  test 'should add an attachment to an entity' do
    entity = entities(:entities_001)

    visit(backend_entity_path(entity))

    assert find(:css, '#title').text.include? entity.full_name

    assert fixture_file('sample_image.png').exist?, 'No image to attach'

    assert find(:css, '.attachment-files')
    assert_not find(:css, '.attachment-files').has_selector?('.file')

    # Input file is hidden to user
    script = "$('#attachments').css({position: 'relative', opacity: 1});"
    page.execute_script(script)

    shoot_screen 'attachments/attach_file'

    attach_file('attachments', 'test/fixture-files/sample_image.png')
    shoot_screen 'attachments/upload_file'

    wait_for_ajax

    assert find(:css, '.attachment-files').find(:css, '.file')

    assert find(:css, '.attachment-files').find(:css, '.file').find(:css, '.file-name').text.include? 'sample_image.png'

    shoot_screen 'attachments/uploaded_file'
  end
end
