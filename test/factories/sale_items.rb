FactoryBot.define do
  factory :sale_item do
    tax
    sale
    amount { 5500.0 }
    pretax_amount { 5000 }
    quantity { 1 }
    reduction_percentage { 0 }
    unit_amount { 5500 }
    unit_pretax_amount { 5000 }
    compute_from { 'amount' }
    currency { 'EUR' }
    association :variant, factory: :sale_variant

    trait :fixed do
      fixed             { true }
      preexisting_asset { true }
    end

  end
end
