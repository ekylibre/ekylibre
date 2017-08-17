FactoryGirl.define do
  factory :product_nature do
    sequence(:name) { |n| "Semence #{n}" }
    association :category, factory: :product_nature_category
    population_counting 'unitary'
    variety 'cultivable_zone'
  end
end
