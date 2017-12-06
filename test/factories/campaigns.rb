FactoryBot.define do
  factory :campaign do
    sequence(:harvest_year) { |n| "203#{n}".to_i }
  end
end
