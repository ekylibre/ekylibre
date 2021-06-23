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

    factory :client_account, parent: :account do
      name { "Compte client" }
      number { 411 }
    end

    trait :supplier do
      sequence(:name) { |n| "Compte fournisseur #{n}" }
      sequence(:auxiliary_number) { |n| (20_000 + n).to_s }
      nature { 'auxiliary' }
      centralizing_account_name { 'suppliers' }
    end

    # @deprecated
    factory :supplier_account, parent: :account do
      name { "Compte fournisseur" }
      number { 401 }
    end

    factory :auxiliary_account, parent: :account do
      name { "Compte auxiliaire" }
      nature { 'auxiliary' }
      number { 41_112_345 }
      auxiliary_number { 12_345 }
      centralizing_account_name { 'clients' }
    end

    factory :stock_account do
      sequence(:number) { |n| "301#{n.to_s.rjust(5, "0")}" }
      sequence(:name) { |n| "Account ##{number}" }
    end

    factory :stock_movement_account do
      sequence(:number) { |n| "603#{n.to_s.rjust(5, "0")}" }
      sequence(:name) { |n| "Account ##{number}" }
    end

    factory :charge_account do
      sequence(:number) { |n| "601#{n.to_s.rjust(5, '0')}" }
      sequence(:name) { |n| "Account ##{number}" }
    end

    factory :fixed_asset_account do
      sequence(:number) { |n| "2154#{n.to_s.rjust(4, '0')}" }
      sequence(:name) { |n| "Account ##{number}" }
    end

    factory :fixed_asset_allocation_account do
      sequence(:number) { |n| "2815#{n.to_s.rjust(4, '0')}" }
      sequence(:name) { |n| "Account ##{number}" }
    end

    factory :fixed_asset_expenses_account do
      sequence(:number) { |n| "68115#{n.to_s.rjust(3, '0')}" }
      sequence(:name) { |n| "Account ##{number}" }
    end
  end
end
