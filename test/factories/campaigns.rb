FactoryBot.define do
  factory :campaign do
    sequence(:harvest_year) { |n| 2030 + n}
  end
end
