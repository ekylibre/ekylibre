FactoryGirl.define do
  factory :reception do
    association :sender, factory: :entity
    association :address, factory: :entity_adress
    pretax_amount 148.3
    currency 'EUR'
    delivery_mode :us
    plannet_at { Time.now }
  end
end
