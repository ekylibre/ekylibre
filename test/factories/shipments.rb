FactoryBot.define do
  factory :shipment do
    association :address, factory: :entity_address
    association :recipient, factory: :entity
    remain_owner { false }
    delivery_mode { :us }
  end
end
