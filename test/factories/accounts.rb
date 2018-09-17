FactoryBot.define do
  factory :account do
    debtor { false }
    reconcilable { false }
    nature { 'general' }
    sequence(:name) { |n| "801 - Compte #{n}" }
    sequence(:number) { |n| "80100#{n}" }
  end

  trait :client do
    sequence(:name) { |n| "411 - Compte client #{n}" }
    sequence(:auxiliary_number) { |n| "10000#{n}" }
    nature { 'auxiliary' }
    centralizing_account_name { 'clients' }
  end

  trait :supplier do
    sequence(:name) { |n| "401 - Compte fournisseur #{n}" }
    sequence(:auxiliary_number) { |n| "20000#{n}" }
    nature { 'auxiliary' }
    centralizing_account_name { 'suppliers' }
  end
end
