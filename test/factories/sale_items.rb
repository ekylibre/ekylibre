FactoryBot.define do
  factory :sale_item do
    tax
    sale
    amount 5000.0
    pretax_amount 4180.602
    quantity 1
    reduction_percentage 0
    unit_amount 5000.0
    unit_pretax_amount 4180.602
    compute_from 'amount'
    currency 'EUR'

    after(:build) do |sale_item|
      sale_item.variant = ProductNatureVariant.last unless sale_item.variant
    end
  end
end
