FactoryBot.define do
  factory :ride do
    started_at { Time.now }
    stopped_at { Time.now + 1.hours }
    nature { 'work' }
    sleep_count { rand(10) }
    provider { { "samsys" => "5f154208b4ff99eae26bf282" } }
    duration {'PT2H25M52S'}
    sleep_duration { 'PT2H8M54S' }
    state { "unaffected" }
    equipment_name { "Machine Étienne " }
    ride_set
  end
end
