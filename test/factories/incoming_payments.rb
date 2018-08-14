FactoryBot.define do
  factory :incoming_payment do
    amount 5000.0
    currency 'EUR'
    association :mode, factory: :incoming_payment_mode
    association :payer, factory: :entity
  end
end
