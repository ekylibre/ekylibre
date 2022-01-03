FactoryBot.define do
  factory :intervention_tool do
    intervention
    association :product, factory: :asset_fixable_product
    reference_name { 'tractor' }
  end

  factory :tractor_tool, class: InterventionTool do
    intervention
    association :product, factory: :tractor
    reference_name { 'tractor' }
  end

  factory :sower_tool, class: InterventionTool do
    intervention
    association :product, factory: :sower
    reference_name { 'sower' }
  end
end
