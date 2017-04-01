# coding: utf-8

require 'test_helper'

class DragAnAnimal < CapybaraIntegrationTest
  setup do
    login_with_user('/backend/animals')
    find(:xpath, "//a[@href='column']").click
    wait_for_ajax
    shoot_screen 'animals/golumn'
  end

  teardown do
    Warden.test_reset!
  end

  test 'should add a new group' do
    group_name = 'My Group'
    find(:xpath, "//div[contains(@class, 'add-group-btn')]/button").click
    shoot_screen 'animals/add-group-modal'
    assert has_content?('Nouveau Troupeau'), 'New Group Modal must appear on button click'
    find(:xpath, "//div[@id='new-group']//input[@type='text']").set group_name
    shoot_screen 'animals/set-group-modal'
    find(:xpath, "//div[@id='new-group']//div[@class='modal-footer']/*[1]").click
    shoot_screen 'animals/insert-group'
    assert has_content?(group_name), 'New Group Modal must be inserted'
  end

  # Drag an animal
  test 'should drag an animal on an empty group to create a new container and move into it' do
    name = 'Bonnemine'
    group = 'Troupeau de génisses A'
    container = 'La Queue du Loup'
    worker = 'Alice'
    nature = 'Vache'

    xpath_animal_checker = "//span[.='#{name}']/../../following-sibling::div[contains(@class,'golumn-item-actions')]//button[contains(@class,'checker')]"
    animal_checker_script = %{ $("span:contains('#{name}')").closest('.golumn-item-infos').siblings('.golumn-item-actions').find('button.checker').mouseenter().click(); }
    xpath_new_container_dropzone = "//span[.='#{group}']/ancestor::div[contains(@class,'panel-heading')]/following-sibling::div[contains(@class,'panel-body')]/div[contains(@class,'add-container ui-droppable')]"
    new_container_dropzone_script = %{ $dropzone = $("span:contains('#{group}')").closest('.panel-heading').siblings('.panel-body').find('div.add-container'); }
    new_container_dropzone_script << %{ $dropzone.show();}

    xpath_animal_dragger = "//span[.='#{name}']/../../following-sibling::div[contains(@class,'golumn-item-dragger')]"

    assert has_content?(name), "#{name} must appear in column"
    assert has_content?(group), "#{group} must appear in groups list"

    page.execute_script animal_checker_script
    page.execute_script new_container_dropzone_script

    assert has_xpath?(xpath_animal_checker), 'Checker for animal cannot be found'
    assert has_xpath?(xpath_animal_dragger), 'Dragger for animal cannot be found'
    assert has_xpath?(xpath_new_container_dropzone), 'Dropzone cannot be found'

    new_container_dropzone = find(:xpath, xpath_new_container_dropzone)
    find(:xpath, xpath_animal_dragger).drag_to(new_container_dropzone)

    # assert has_content?('Ajouter un emplacement'), "New container Modal must appear on button click"

    shoot_screen 'animals/new-container-modal'

    wait_for_ajax

    find(:xpath, "//div[@id='new-container']//select[1]").find(:xpath, "option[.='#{container}']").select_option
    find(:xpath, "//div[@id='new-container']//div[@class='modal-footer']/button[1]").click

    # assert has_content?('Déplacement'), "Moving Modal must appear on button click"
    shoot_screen 'animals/moving-modal'

    assert_equal(name, find(:xpath, "//div[@id='move-animal']//div[@class='modal-body']/div[2]/ul").find(:xpath, "li[.='#{name}']").text, 'Animal is missing on moving modal')
    assert_equal(group, find(:xpath, "//div[@id='move-animal']//div[@class='modal-body']/div[3]/ul").find(:xpath, "li[.='#{group}']").text, 'Group is missing on moving modal')
    assert_equal(container, find(:xpath, "//div[@id='move-animal']//div[@class='modal-body']/div[4]/ul").find(:xpath, "li[.='#{container}']").text, 'Container is missing on moving modal')

    find(:xpath, "//div[@id='move-animal']//div[@class='modal-body']//input[@name='started_at']").set '2015-06-17 09:00'
    find(:xpath, "//div[@id='move-animal']//div[@class='modal-body']//input[@name='stopped_at']").set '2015-06-17 12:00'
    find(:xpath, "//div[@id='move-animal']//div[@class='modal-body']//select[@name='worker']").find(:xpath, "option[.='#{worker}']").select_option

    find(:xpath, "//div[@id='move-animal']//div[@class='modal-body']//input[@name='check_nature']").set true
    find(:xpath, "//div[@id='move-animal']//div[@class='modal-body']//select[@name='nature']").find(:xpath, "option[.='#{nature}']").select_option
    shoot_screen 'animals/filled-moving-modal'

    find(:xpath, "//div[@id='move-animal']//div[@class='modal-footer']/button[1]").click
    # assert_equal(name, find(:xpath,"//span[.='#{group}']//span[.='#{name}']"), "Animal hasn't been correctly moved")

    shoot_screen 'animals/new-golumn-after-moving-an-animal'
  end
end
