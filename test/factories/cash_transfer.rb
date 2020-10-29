FactoryBot.define do
  factory :cash_transfer do
    transfered_at { Date.civil(2010, 8, 1) }
    association :emission_cash, factory: :cash
    emission_amount { 1000 }
    currency_rate { 2 }
    association :reception_cash, factory: :cash
  end
end
