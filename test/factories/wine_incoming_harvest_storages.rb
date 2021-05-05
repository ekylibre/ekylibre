FactoryBot.define do
  factory :wine_incoming_harvest_storage do
    quantity_value { 0.3438e1 }
    quantity_unit { "hectoliter" }
    wine_incoming_harvest
    storage
  end
end
