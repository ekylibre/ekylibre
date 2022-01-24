FactoryBot.define do
  factory :wine_incoming_harvest_press do
    quantity_value { 0.1e3 }
    quantity_unit { "hectoliter" }
    pressing_schedule { "Programme 1" }
    pressing_started_at { Time.zone.now }
    wine_incoming_harvest
  end
end
