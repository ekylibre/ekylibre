FactoryBot.define do
  factory :account do
    debtor { false }
    reconcilable { false }
    sequence(:name) { |n| "801 - Compte #{n}" }
    sequence(:number) { |n| "801000000#{n}" }

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
  end
end
