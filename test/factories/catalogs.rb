FactoryGirl.define do
  factory :catalog do
    sequence(:code) { |n| "VENTE {n}" }
    sequence(:name) { |n| "Vente {n}" }
  end
end
