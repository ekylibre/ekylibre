FactoryBot.define do
  factory :activity_production do
    activity
    campaign

    factory :corn_activity_production do
      support_shape { Charta.new_geometry("SRID=4326;MULTIPOLYGON (((-0.9428286552429199 43.77818419848836, -0.9408894181251525 43.777330143623416, -0.9400096535682678 43.77828102933575, -0.9415814280509949 43.778892996664055, -0.9428286552429199 43.77818419848836)))") }
      association :activity, factory: :corn_activity
    end

    factory :lemon_activity_production do
      support_shape { Charta.new_geometry("SRID=4326;MultiPolygon (((-1.017533540725708 44.23605999218229, -1.0204195976257324 44.236744122959124, -1.0197114944458008 44.238758034804555, -1.0165786743164062 44.238143107200145, -1.017533540725708 44.23605999218229)))") }
      association :activity, factory: :lemon_activity

      trait :organic do
        association :activity, factory: %i[lemon_activity organic]
      end
    end
  end
end
