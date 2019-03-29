FactoryBot.define do
  factory :corn_inspection, class: Inspection do
    sampled_at                  { DateTime.now }
    sampling_distance           { 3.in :meter }
    implanter_rows_number       { 3 }
    implanter_application_width { 1.in :meter }

    association                 :product,  factory: :corn_plant
    association                 :activity, :fully_inspectable, factory: :corn_activity

    product_net_surface_area    { product.shape.area.in(:square_meter) }

    after(:create) do |instance|
      create :inspection_point,
             inspection: instance,
             nature: instance.activity.inspection_point_natures.first
      create :inspection_calibration,
             inspection: instance,
             nature: instance.activity.inspection_calibration_natures.first
    end
  end
end
