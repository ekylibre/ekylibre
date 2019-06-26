FactoryBot.define do
  factory :intervention_tool do
    intervention
    association :product, factory: :asset_fixable_product
    reference_name { 'tractor' }
  end
end
