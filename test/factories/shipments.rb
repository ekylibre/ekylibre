FactoryGirl.define do
  factory :shipment do
    association :address, factory: :entity_address
    association :recipient, factory: :entity
    nature :outgoing
    planned_at { Time.now }
    remain_owner false
    delivery_mode :us
  end
end
