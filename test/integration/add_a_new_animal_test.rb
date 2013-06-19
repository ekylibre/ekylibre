# encoding:UTF-8
require 'test_helper'

class AddANewAnimalTest < CapybaraIntegrationTest

  test "adding an animal" do
    visit('/authentication/sign_in')
    fill_in('user_email', :with => 'gendo@nerv.jp')
    fill_in('user_password', :with => '12345678')
    click_button('Connexion')
    visit('/backend/animals/new')
    fill_unroll("animal-nature-input", with: "vac", select: "vache")
    select('Bos', :from => 'animal[variety]')
    fill_in('animal[name]', :with => 'MARGUERITTE')
    choose("animal_sex_female")
    fill_in("animal[work_number]", :with => '9253')
    fill_in("animal[identification_number]", :with => 'FR17123456')
    fill_in("animal[born_at]", :with => '01/01/2013')
    fill_unroll("animal-owner-input", with: "tol", select: "Toley LTD")
    attach_file('animal[picture]',Rails.root.join("test", "fixtures", "files", "animals-ld", "cow-8580.jpg"))
    click_on("Créer")
    save_screenshot 'tmp/capybara/animal_add.png'
  end

  test "view an animal" do
    visit ('/backend/animals')
    page.should have_content('MARGUERITTE')
    save_screenshot 'tmp/capybara/animal_view.png'
  end

  test "adding an incident" do
    #visit('/backend/animals/10')
    #click_button('Nouveau...')
    visit('/backend/incidents/new?target_id=10&target_type=Animal')
    fill_in('incident[name]', :with => 'Test incident')
    select('Mammite', :from => 'incident[nature]')
    fill_in("incident[observed_at]", :with => '01/06/2013')
    choose("incident_priority_1")
    choose("incident_gravity_3")
    click_on("Créer")
    save_screenshot 'tmp/capybara/incident_add.png'
  end

  test "view an incident on an animal" do
    visit ('/backend/incidents')
    save_screenshot 'tmp/capybara/animal_incident_view.png'
  end



end
