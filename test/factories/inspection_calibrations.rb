FactoryBot.define do
  factory :inspection_calibration do
    net_mass_value     { 15 }
    items_count_value  { 500 }

    minimal_size_value { 8 }
    maximal_size_value { 13 }
  end
end
