FactoryGirl.define do
  factory :product_nature do
    sequence(:name)     { |n| "Semence #{n}" }
    population_counting 'unitary'
    variety             'cultivable_zone'

    association         :category, factory: :product_nature_category
  end

  factory :plants_nature, class: ProductNature do
    sequence(:name)     { |n| "Plant nature - TEST#{n.to_s.rjust(8, '0')}" }
    population_counting :unitary
    variety             :plant

    association         :category, factory: :plants_category
  end
end
