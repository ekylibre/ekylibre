FactoryBot.define do
  factory :incoming_payment do
    transient do
      at { nil }
    end
    amount { 5000.0 }
    currency { 'EUR' }
    association :mode, factory: :incoming_payment_mode
    association :payer, factory: :entity
    provider { }
    to_bank_at { at }
    paid_at { at }
  end
end
