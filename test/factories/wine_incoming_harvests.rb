FactoryBot.define do
  factory :wine_incoming_harvest do
    ticket_number { "LOT_01" }
    received_at { Time.new(2017, 8, 20)}
    quantity_value { 0.5e2 }
    quantity_unit { "hectoliter" }
    additional_informations { { "pressing_schedule"=>"programme standard ", "pressing_started_at"=>"00:56" } }

    trait :with_wine_incoming_harvest_plants do
      after(:create) do |wine_incoming_harvest|
        create_list(:wine_incoming_harvest_plant, Random.rand(1..4), wine_incoming_harvest: wine_incoming_harvest)
      end
    end

    trait :with_wine_incoming_harvest_presses do
      after(:create) do |wine_incoming_harvest|
        create_list(:wine_incoming_harvest_press, Random.rand(1..4), wine_incoming_harvest: wine_incoming_harvest)
      end
    end

    trait :with_wine_incoming_harvest_storages do
      after(:create) do |wine_incoming_harvest|
        create_list(:wine_incoming_harvest_storage, Random.rand(1..4), wine_incoming_harvest: wine_incoming_harvest)
      end
    end
  end
end
