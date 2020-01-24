FactoryBot.define do
  factory :worker do
    type { 'Worker' }
    association :person, factory: :entity
    association :variant, factory: :worker_variant
  end
end
