require 'test_helper'

class DragAnAnimal < CapybaraIntegrationTest

  setup do
    # Need to go on page to set tenant
    I18n.locale = @locale = ENV["LOCALE"] || I18n.default_locale
    visit("/authentication/sign_in?locale=#{@locale}")
    resize_window(1366, 768)
    shoot_screen "authentication/sign_in"
    login_as(users(:users_001), scope: :user)
    visit('/backend/animals')
    find(:xpath, "//a[@href='column']").click
    wait_for_ajax
    shoot_screen "animals/golumn"
  end

  teardown do
    Warden.test_reset!
  end

  test "should add a new group" do
    group_name = 'My Group'
    find(:xpath, "//div[contains(@class, 'add-group-btn')]/button").click
    shoot_screen "animals/add-group-modal"
    assert has_content?('Nouveau Troupeau'), "New Group Modal must appear on button click"
    find(:xpath, "//div[@id='new-group']//input[@type='text']").set group_name
    shoot_screen "animals/set-group-modal"
    find(:xpath, "//div[@id='new-group']//div[@class='modal-footer']/*[1]").click
    shoot_screen "animals/insert-group"
    assert has_content?(group_name), "New Group Modal must be inserted"

  end

  # Drag an animal
  test "should drag an animal on an empty group to create a new container and move into it" do
    name = 'Bonnemine'
    group = 'Troupeau de génisses A'
    xpath_animal_actions = "//span[.='#{name}']/../../following-sibling::div[contains(@class,'golumn-item-actions')]"
    # xpath_animal_checker = "//span[.='#{name}']/../../following-sibling::div[contains(@class,'golumn-item-actions')]//button[contains(@class,'checker')]"
    xpath_animal_checker = "//span[.='#{name}']/../../following-sibling::div[contains(@class,'golumn-item-actions')]/div[1]/button[1]"
    xpath_new_container_dropzone = "//span[.='#{group}']/ancestor::div[contains(@class,'panel-heading')]/following-sibling::div[contains(@class,'panel-body')]/div[contains(@class,'add-container ui-droppable')]"
    xpath_animal_dragger = "//span[.='#{name}']/../../following-sibling::div[contains(@class,'golumn-item-dragger')]"

    assert has_content?(name), "#{name} must appear in column"
    assert has_content?(group), "#{group} must appear in groups list"
    assert has_xpath?(xpath_animal_actions), "Action section for animal cannot be found"
    assert has_xpath?(xpath_animal_checker), "Checker for animal cannot be found"


    assert has_xpath?(xpath_animal_dragger), "Dragger for animal cannot be found"
    assert has_xpath?(xpath_new_container_dropzone), "New container dropzone cannot be found"


    # assert_nothing_raised { find(:xpath, xpath_animal_checker).click }

    new_container_dropzone = find(:xpath, xpath_new_container_dropzone)
    find(:xpath, xpath_animal_dragger).drag_to(new_container_dropzone)
  end



end
