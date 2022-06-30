FactoryBot.define do
  factory :shipment do
    association :address, factory: %i[entity_address mail]
    association :recipient, factory: :entity
    remain_owner { false }
    delivery_mode { :us }
  end
end
