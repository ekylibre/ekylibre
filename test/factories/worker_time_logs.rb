FactoryBot.define do
  factory :worker_time_log do
    association :worker, factory: :worker
    started_at { Time.now - 1.hours }
    stopped_at { Time.now }
    duration { 3600 }
  end
end
