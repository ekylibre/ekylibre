FactoryBot.define do
  factory :account do
    debtor false
    reconcilable false
    nature 'general'
    sequence(:name) { |n| "801 - Compte #{n}" }
    sequence(:number) { |n| "8010000#{n}" }
  end

  trait :client do
    auxiliary_number 1234
    nature 'auxiliary'
    name '4111234 - Compte fournisseur'
    centralizing_account_name 'clients'
  end

  trait :supplier do
    auxiliary_number 1234
    nature 'auxiliary'
    name '4011234 - Compte fournisseur'
    centralizing_account_name 'suppliers'
  end
end
