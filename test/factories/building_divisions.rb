FactoryBot.define do
  factory :building_division do
    association :category, factory: :building_division_category
    association :nature, factory: :building_division_nature
    association :variant, factory: :building_division_variant
    variety { 'building_division' }
  end
end
