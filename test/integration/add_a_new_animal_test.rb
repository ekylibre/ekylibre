# encoding:UTF-8
require 'test_helper'

class AddANewAnimalTest < CapybaraIntegrationTest
  
  setup do
    visit('/authentication/sign_in')
    # fill_in('user_email', :with => 'gendo@nerv.jp')
    # fill_in('user_password', :with => '12345678')
    shoot_screen "authentication/sign_in"
    # click_button('Connexion')
    login_as(users(:users_001), :scope => :user)
    visit('/backend')
    shoot_screen "backend"
  end  

  test "add an animal" do
    # visit('/authentication/sign_in')
    # fill_in('user_email', :with => 'gendo@nerv.jp')
    # fill_in('user_password', :with => '12345678')
    # shoot_screen "authentication/sign_in"
    # click_button('Connexion')
    visit('/backend/animals/new?variant_id=7')
    shoot_screen "animals/new"
    # fill_unroll("animal-nature-input", with: "vac", select: "vache")
    select('bos', :from => 'animal[variety]')
    fill_in('animal[name]', :with => 'MARGUERITTE')
    # choose("animal_sex_female")
    fill_in("animal[work_number]", :with => '9253')
    fill_in("animal[identification_number]", :with => 'FR17123456')
    fill_in("animal_born_at", :with => '01/01/2013')
    # fill_unroll("animal-owner-input", with: "tol", select: "Toley LTD")
    attach_file('animal[picture]', Rails.root.join("test", "fixtures", "files", "animals-ld", "cow-8580.jpg"))
    shoot_screen "animals/new-before_create"
    click_on("Créer")
    shoot_screen "animals/create"
  end

  test "view an animal" do
    visit ('/backend/animals')
    shoot_screen "animals/index"
    page.should have_content('MARGUERITE')
  end

  test "add an incident" do
    # visit('/backend/animals/10')
    # click_button('Nouveau...')
    visit('/backend/incidents/new?target_id=7004&target_type=Animal')
    shoot_screen "incidents/new"
    fill_in('incident[name]', :with => 'Test incident')
    select('Mammite', :from => 'incident[nature]')
    fill_in("incident_observed_at", :with => '01/06/2013')
    choose("incident_priority_1")
    choose("incident_gravity_3")
    click_on("Créer")
    shoot_screen "incidents/create"
  end

  test "view an incident on an animal" do
    visit ('/backend/incidents')
    shoot_screen "incidents/index"
  end

end
