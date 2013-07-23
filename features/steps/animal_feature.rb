class Spinach::Features::AnimalFeature < Spinach::FeatureSteps
  step 'an animal exists' do
    pending 'step not implemented'
  end

  step 'I am on animals page' do
    visit backend_animals_path
  end

  step 'I should see "Animals"' do
    page.has_content?('MARGUERITTE').must_equal true
    save_screenshot 'tmp/capybara/animal_view.png'
  end
end
