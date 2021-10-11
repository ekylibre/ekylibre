FactoryBot.define do
  factory :intervention_tool do
    intervention
    association :product, factory: :asset_fixable_product
    reference_name { 'tractor' }
  end

  factory :tractor_tool, class: InterventionTool do
    transient do
      initial_born_at {}
    end

    intervention
    reference_name { 'tractor' }

    after(:build) do |tool, evaluator|
      tool.product = build :tractor, initial_born_at: evaluator.initial_born_at
    end
  end

  factory :sower_tool, class: InterventionTool do
    intervention
    association :product, factory: :sower
    reference_name { 'sower' }
  end
end
