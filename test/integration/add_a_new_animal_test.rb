require 'test_helper'

class AddANewAnimalTest < CapybaraIntegrationTest


  test "adding an animal" do
    visit('/authentication/sign_in')
    fill_in('user_email', :with => 'gendo@nerv.jp')
    fill_in('user_password', :with => '12345678')
    click_button('Connexion')
    visit('/backend/animals/new')
    #fill_in('animal_nature',:with => 'Bovin')
    #fill_in('animal_name', :with => 'MARGUERITTE')
    #choose("female")
    #check("animal_reproductor")
    #fill_in("work_number", :with => '9253')
    #fill_in("identification_number", :with => 'FR17123456')
    #fill_in("born_at", :with => '01/01/2013')
    #attach_file('picture',Rails.root.join("test", "fixtures", "files", "animals-ld", "cow-8580.jpg"))
    Capybara::Screenshot.screenshot_and_save_page
    click_button("submit")
    Capybara::Screenshot.screenshot_and_save_page
  end

end
