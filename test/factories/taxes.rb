FactoryBot.define do
  factory :tax do
    country { 'fr' }
    nature { 'intermediate_vat' }
    sequence(:name) { |n| "TVA française intermédiaire #{n}" }
    amount 10
    association :collect_account, factory: :account
    association :deduction_account, factory: :account
  end
end
