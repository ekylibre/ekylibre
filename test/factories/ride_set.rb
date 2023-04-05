FactoryBot.define do
  factory :ride_set do
    started_at { Time.now }
    stopped_at { Time.now + 1.hours }
    road { rand(5) }
    nature { 'work' }
    sleep_count { rand(5) }
    provider { { "samsys" => "5f154208b4ff99eae26bf282" } }
    duration {'PT2H25M52S'}
    sleep_duration { 'PT2H8M54S' }

    after(:create) do |ride_set|
      create(:ride_set_equipment, ride_set: ride_set)
    end
  end

  factory :ride_set_equipment do
    association :ride_set
    association :product, factory: :tractor
    nature { "main" }
  end
end
