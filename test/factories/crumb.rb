FactoryBot.define do
  factory :crumb do
    nature { "point"}
    geolocation { Charta.new_point(2.541493, 50.398378).to_rgeo }
    accuracy {4}
    device_uid {"samsys"}
    read_at { Time.now }
    metadata { { "speed"=>0.2 } }
    provider { { "id"=>"5fa3a963817d0c0cf10ec32a", "name"=>"samsys_crumb", "vendor"=>"Samsys" } }

    trait :point do
      nature { "point" }
    end

    trait :hard_start do
      nature { "hard_start" }
    end

    trait :hard_stop do
      nature { "hard_stop" }
    end

    trait :pause do
      nature { "pause" }
    end

    ride
  end
end
