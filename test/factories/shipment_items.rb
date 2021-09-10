FactoryBot.define do
  factory :shipment_item do
    association :shipment
    association :variant, factory: :product_nature_variant
    association :source_product, factory: :product
    conditioning_quantity { 1 }

    after(:build) do |shipment_item|
      shipment_item.conditioning_unit = shipment_item.variant.guess_conditioning[:unit]
    end
  end
end
