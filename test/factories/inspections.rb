FactoryGirl.define do
  factory :inspection do
    sampled_at                  { DateTime.now }
    sampling_distance           3.in :meter
    implanter_rows_number       3
    implanter_application_width 1.in :meter

    association                 :product,  factory: :corn_plant
    association                 :activity, :fully_inspectable, factory: :corn_activity
  end
end
