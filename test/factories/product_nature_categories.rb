FactoryBot.define do
  factory :product_nature_category do
    sequence(:name) { |n| "Service bancaire #{n}" }
    association :product_account, factory: :account
  end

  factory :plants_category, class: ProductNatureCategory do
    sequence(:name) { |n| "Crops - TEST#{n.to_s.rjust(8, '0')}" }
  end
end
