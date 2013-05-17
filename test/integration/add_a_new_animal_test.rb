# encoding:UTF-8
require 'test_helper'

class AddANewAnimalTest < CapybaraIntegrationTest


  test "adding an animal" do
    visit('/authentication/sign_in')
    fill_in('user_email', :with => 'gendo@nerv.jp')
    fill_in('user_password', :with => '12345678')
    click_button('Connexion')
    visit('/backend/animals/new')
    #FIXME : add an AJAX helpers to capybara for testing unroll field
    # http://stackoverflow.com/questions/13187753/rails3-jquery-autocomplete-how-to-test-with-rspec-and-capybara/13213185#13213185 
    # http://jackhq.tumblr.com/post/3728330919/testing-jquery-autocomplete-using-capybara
    fill_in('animal[nature_id]',:with => 'bov')
    #sleep 5
    #execute_script %Q{ $('.item-selected data-item-label:contains("Bovin")').trigger("mouseenter").click(); }
    fill_in('animal[name]', :with => 'MARGUERITTE')
    choose("animal_sex_female")
    check("animal[reproductor]")
    fill_in("animal[work_number]", :with => '9253')
    fill_in("animal[identification_number]", :with => 'FR17123456')
    fill_in("animal[born_at]", :with => '01/01/2013')
    attach_file('animal[picture]',Rails.root.join("test", "fixtures", "files", "animals-ld", "cow-8580.jpg"))
    save_screenshot 'tmp/toto.png'
    click_on("Créer")
  end

end
