FactoryBot.define do
  factory :account do
    debtor { false }
    reconcilable { false }
    nature { 'general' }
    sequence(:name) { |n| "Compte 801 - #{n}" }
    sequence(:number) { |n| (801_000 + n).to_s }
    already_existing { false }

    trait :client do
      sequence(:name) { |n| "Compte client #{n}" }
      sequence(:auxiliary_number) { |n| (10_000 + n).to_s }
      nature { 'auxiliary' }
      centralizing_account_name { 'clients' }
    end

    trait :supplier do
      sequence(:name) { |n| "Compte fournisseur #{n}" }
      sequence(:auxiliary_number) { |n| (20_000 + n).to_s }
      nature { 'auxiliary' }
      centralizing_account_name { 'suppliers' }
    end
  end
end
