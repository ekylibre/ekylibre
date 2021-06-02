FactoryBot.define do
  factory :wine_incoming_harvest_plant do
    harvest_percentage_received { 0.1e3 }
    wine_incoming_harvest
    plant
  end
end
