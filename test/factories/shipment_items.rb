FactoryBot.define do
  factory :shipment_item do
    association :shipment
    association :variant, factory: :product_nature_variant
    association :source_product, factory: :product
  end
end
