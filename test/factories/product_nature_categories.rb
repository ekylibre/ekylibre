FactoryGirl.define do
  factory :product_nature_category do
    sequence(:name) { |n| "Service bancaire #{n}" }
  end
end
