FactoryBot.define do
  factory :inventory do
    transient do
      year { nil }
      month { 12 }
      day { 31 }
    end

    financial_year factory: :financial_year

    achieved_at { Date.new year, month, day }
    sequence(:name) { |n| "#{year} - Inventory #{n}" }
  end
end