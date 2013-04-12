require 'test_helper'

class AddANewAnimalTest < CapybaraIntegrationTest


  test "adding an animal" do
    visit('/authentication/sign_in')
    fill_in('user_email', :with => 'gendo@nerv.jp')
    fill_in('user_password', :with => 'secret')
    click_button(I18n.translate('devise.sessions.new.sign_in'))
    visit('/backend/animals/new')
    fill_in('nature',:with => 'Bovin')
    fill_in('name', :with => 'MARGUERITTE')
    choose("Femelle")
    check("Reproducteur")
    fill_in("work_number", :with => '9253')
    fill_in("identification_number", :with => 'FR17123456')
    fill_in("born_at", :with => '01/01/2013')
    attach_file('picture',Rails.root.join("test", "fixtures", "files", "animals-ld", "cow-8580.jpg"))
    click_button("submit")
    Capybara::Screenshot.screenshot_and_save_page
  end

end
