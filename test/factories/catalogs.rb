FactoryGirl.define do
  factory :catalog do
    sequence(:name)     { |n| "Catalog #{n}" }
    sequence(:code)     { |n| "COUT #{n}" }
    usage 'travel_cost'
    by_default true
  end
end
