# encoding:UTF-8
require 'test_helper'

class AddANewAnimalTest < CapybaraIntegrationTest

  test "adding an animal" do
    visit('/authentication/sign_in')
    fill_in('user_email', :with => 'gendo@nerv.jp')
    fill_in('user_password', :with => '12345678')
    click_button('Connexion')
    visit('/backend/animals/new')
    fill_unroll("animal-nature-input", with: "bov", select: "Bovin")
    fill_in('animal[name]', :with => 'MARGUERITTE')
    choose("animal_sex_female")
    check("animal[reproductor]")
    fill_in("animal[work_number]", :with => '9253')
    fill_in("animal[identification_number]", :with => 'FR17123456')
    fill_in("animal[born_at]", :with => '01/01/2013')
    fill_unroll("animal-owner-input", with: "gen", select: "Gendo IKARI")
    attach_file('animal[picture]',Rails.root.join("test", "fixtures", "files", "animals-ld", "cow-8580.jpg"))
    click_on("Créer")
    save_screenshot 'tmp/capybara/animal_add.png'
  end

  test "view an animal" do
    visit ('/backend/animals')
    save_screenshot 'tmp/capybara/animal_view.png'
  end



end
