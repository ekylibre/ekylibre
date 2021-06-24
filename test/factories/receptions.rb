FactoryBot.define do
  factory :reception do
    association :sender, factory: :entity
    association :address, factory: :entity_address
    pretax_amount { 148.3 }
    currency { 'EUR' }
    delivery_mode { :us }
    given_at { DateTime.new(2018, 1, 1) }
  end
end
