# coding: utf-8

require 'test_helper'

class AddAnAnimalTest < CapybaraIntegrationTest
  setup do
    login_with_user
  end

  teardown do
    Warden.test_reset!
  end

  # Add a cow
  test 'add an animal' do
    visit('/backend/animals/new')
    shoot_screen 'animals/new_without_variant'
    id = ProductNatureVariant.of_variety('bos').first.id
    visit("/backend/animals/new?variant_id=#{id}")
    shoot_screen 'animals/new'
    select(Nomen::Variety[:bos].human_name, from: 'animal[variety]')
    fill_in('animal[name]', with: 'Linette')
    fill_in('animal[work_number]', with: '9253')
    fill_in('animal[identification_number]', with: 'FR17129253')
    fill_in('animal[initial_population]', with: '1')
    fill_unroll('animal_initial_mother_id', with: 'isa', select: 'Isabelle', name: :animals)
    attach_file('animal[picture]', fixture_files_path.join('cow_picture.jpg'))
    shoot_screen 'animals/new-before_create'
    click_on(:create.tl)
    shoot_screen 'animals/new-after_create'
    visit('/backend/animals')
    assert has_content?('Linette'), 'Linette must appear in animals list after its creation'
  end

  # View a cow
  test 'view an animal' do
    visit '/backend/animals'
    shoot_screen 'animals/index'
    name = 'Bonnemine'
    assert has_content?(name), "#{name} must appear in animals list"
    click_link name
    shoot_screen "animals/show-#{name.underscore}"
    # assert has_content?('female'), "#{name} should appear as a female"
  end

  # Add an issue on the current animal
  test 'add an issue' do
    visit('/backend/issues/new?target_id=7004&target_type=Animal')
    shoot_screen 'issues/new'
    # fill_in('issue[name]', with: "3ème mammite de l'année")
    select('Mammite', from: 'issue[nature]')
    choose('issue_priority_1')
    choose('issue_gravity_3')
    fill_in('issue_observed_at', with: '2013-06-01 14:50')
    click_on(:create.tl)
    shoot_screen 'issues/create'
  end

  test 'view an issue on an animal' do
    visit '/backend/issues'
    shoot_screen 'issues/index'
  end
end
