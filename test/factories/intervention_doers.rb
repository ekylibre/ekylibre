FactoryBot.define do
  factory :driver, class: InterventionDoer do
    intervention
    association :product, factory: :worker
    reference_name { 'driver' }
  end
end
