FactoryBot.define do
  factory :fixed_asset do
    transient do
      amount { 42 }
      percentage { 20.0 }
    end

    sequence(:name) { |n| "Fixed asset #{n}" }
    depreciable_amount { amount }
    depreciation_method { :linear }
    depreciation_percentage { percentage }
    currency { :EUR }

    association :journal, factory: :journal
    association :allocation_account, factory: :fixed_asset_allocation_account
    association :asset_account, factory: :fixed_asset_account
    association :expenses_account, factory: :fixed_asset_expenses_account

    trait(:yearly) { depreciation_period { :yearly } }
    trait(:monthly) { depreciation_period { :monthly } }

    trait(:not_depreciable) {
      depreciation_method { :none }
      allocation_account { nil }
      expenses_account { nil }
      stopped_on { nil }
    }
    trait(:linear) { depreciation_method { :linear } }
    trait :regressive do
      transient do
        coefficient { 1.75 }
      end

      depreciation_method { :regressive }
      depreciation_fiscal_coefficient { coefficient }
    end

    trait :in_use do
      after(:create) do |fa|
        FixedAsset::Transitions::StartUp.new(fa).run!
        fa.reload
      end
    end
  end
end
