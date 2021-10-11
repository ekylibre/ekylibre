FactoryBot.define do
  factory :reception_item do
    reception
    association :variant, factory: :deliverable_variant
    sequence(:product_name) { |n| "product name #{n}" }
    conditioning_quantity { 1 }

    after(:build) do |reception_item|
      reception_item.conditioning_unit = reception_item.variant.guess_conditioning[:unit]
    end
  end
end
