FactoryGirl.define do
  factory :campaign do
    sequence(:harvest_year) { |n| "201#{n}".to_i }
  end
end
