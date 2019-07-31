FactoryBot.define do
  factory :purchase_item do
    association :tax
    association :purchase, factory: :purchase_invoice
    account
    amount { 1848.0 }
    pretax_amount { 1545.15 }
    quantity { 1 }
    reduction_percentage { 0 }
    unit_amount { 1848.0 }
    unit_pretax_amount { 1545.15 }
    currency { 'EUR' }

    trait :of_purchase_order do
      association :purchase, factory: :purchase_order
    end

    after(:build) do |purchase_item|
      purchase_item.variant = ProductNatureVariant.last unless purchase_item.variant
    end
  end
end
