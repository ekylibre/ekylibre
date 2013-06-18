# encoding:UTF-8
require 'test_helper'

class AddANewAnimalTest < CapybaraIntegrationTest

  test "adding an incident" do
    visit('/backend/animal/10')
    click_button('Nouveau...')   
    fill_in('incident[name]', :with => 'Test incident')
    select('Mammite', :from => 'animal[nature]')
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
