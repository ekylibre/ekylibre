FactoryGirl.define do
  factory :tax do
    country 'fr'
    nature 'intermediate_vat'
    sequence(:name) { |n| "TVA française intermédiaire #{n}" }
    association :collect_account, factory: :account
    association :deduction_account, factory: :account
  end
end
